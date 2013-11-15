
############################################################################################################
njs_path                  = require 'path'
#...........................................................................................................
TRM                       = require 'coffeenode-trm'
rpr                       = TRM.rpr.bind TRM
badge                     = 'cnd-limit'
log                       = TRM.get_logger 'plain', badge
info                      = TRM.get_logger 'info',  badge
alert                     = TRM.get_logger 'alert', badge
debug                     = TRM.get_logger 'debug', badge
warn                      = TRM.get_logger 'warn',  badge
help                      = TRM.get_logger 'help',  badge
#...........................................................................................................
### patched version of https://github.com/jhurliman/node-rate-limiter ###
LIMITER                   = require '../limiter'
#...........................................................................................................
misfit                    = {}
home                      = process.cwd()
options_route             = njs_path.join home, 'limit-options'


############################################################################################################
### Load options: ###
info "loading configuration settings from", TRM.lime options_route
try
  O = require options_route
catch error
  if /^Cannot find module/.test error[ 'message' ]
    log()
    alert "unable to load #{TRM.lime options_route}"
    alert "please copy file", TRM.lime 'coffeenode-limit/limit-options.json'
    alert "to", TRM.lime home
    alert "and edit it to match your needs"
    log()
    process.exit()
  else
    throw error


#===========================================================================================================
# OBJECT CREATION
#-----------------------------------------------------------------------------------------------------------
@new_registry = ->
  #.........................................................................................................
  R =
    '~isa':                 'PERMESSO/registry'
    'gid-by-uid':           {}
    'description-by-gid':   {}
    'arguments-by-gid':     {}
    '%limiter-by-uid':      {}
  #.........................................................................................................
  if O[ 'description-by-gid' ]?
    for gid, description of O[ 'description-by-gid' ]
      @new_group R, gid, description
  #.........................................................................................................
  if O[ 'gid-by-uid' ]?
    for uid, gid of O[ 'gid-by-uid' ]
      @new_user R, uid, gid
  #.........................................................................................................
  unless R[ 'description-by-gid' ][ 'default' ]?
    @new_group R, 'default', '1 hit per second with delay'
  #.........................................................................................................
  return R

#-----------------------------------------------------------------------------------------------------------
@new_group = ( me, gid, description ) ->
  throw new Error "GID #{rpr gid} already registered" if me[ 'description-by-gid' ][ gid ]?
  me[ 'description-by-gid' ][ gid ] = description
  me[   'arguments-by-gid' ][ gid ] = @parse_description me, description
  return me

#-----------------------------------------------------------------------------------------------------------
@new_user = ( me, uid, gid ) ->
  throw new Error "UID #{rpr uid} already registered" if me[  'gid-by-uid' ][ uid ]?
  throw new Error "GID #{rpr gid} unknown" unless me[ 'description-by-gid' ][ gid ]?
  me[ 'gid-by-uid' ][ uid ] = gid
  return me

#-----------------------------------------------------------------------------------------------------------
@new_limiter = ( me, gid ) ->
  limiter_arguments = me[ 'arguments-by-gid' ][ gid ]
  throw new Error "GID #{rpr gid} unknown" unless limiter_arguments?
  return new LIMITER.RateLimiter limiter_arguments...


#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
@gid_from_uid = ( me, uid, fallback = misfit ) ->
  R = me[ 'gid-by-uid' ][ uid ]
  unless R?
    throw new Error "UID #{rpr uid} unknown" if fallback is misfit
    @new_user me, uid, fallback if ( @_gids_of me )[ fallback ]?
    return fallback
  return R

#-----------------------------------------------------------------------------------------------------------
@gids_of = ( me, uid ) ->
  return ( uid for uid of @_gids_of me, gid )

#-----------------------------------------------------------------------------------------------------------
@uids_of = ( me, gid ) ->
  return ( uid for uid of @_uids_of me, gid )

#-----------------------------------------------------------------------------------------------------------
@_uids_of = ( me, gid ) ->
  R = {}
  if gid? then  R[ uid ] = 1 for uid, gid_ of me[ 'gid-by-uid' ] when gid is gid_
  else          R[ uid ] = 1 for uid, gid_ of me[ 'gid-by-uid' ]
  return R

#-----------------------------------------------------------------------------------------------------------
@_gids_of = ( me, uid ) ->
  R = {}
  if uid? then  R[ gid ] = 1 for uid_, gid of me[ 'gid-by-uid' ] when uid is uid_
  else          R[ gid ] = 1 for uid_, gid of me[ 'gid-by-uid' ]
  return R

#-----------------------------------------------------------------------------------------------------------
@set_gid = ( me, uid, gid ) ->
  throw new Error "UID #{rpr uid} unknown" unless me[         'gid-by-uid' ][ uid ]?
  throw new Error "GID #{rpr gid} unknown" unless me[ 'description-by-gid' ][ gid ]?
  me[ 'gid-by-uid' ][ uid ] = gid
  return me

#-----------------------------------------------------------------------------------------------------------
@permesso = ( me, uid, handler ) ->
  limiter = @fetch_limiter me, uid
  #.........................................................................................................
  limiter.removeTokens 1, ( error, remaining_count, ms_to_wait ) ->
    # error will be set if we request more than the maximum number of
    # requests we set in the constructor
    if error? or remaining_count < 0
      handler null, false, ms_to_wait
    else
      handler null, 'avanti', ms_to_wait
  #.........................................................................................................
  return null


#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
@fetch_limiter = ( me, uid ) ->
  R = me[ '%limiter-by-uid' ][ uid ]
  return R if R?
  gid                             = @gid_from_uid me, uid, 'default'
  R                               = @new_limiter me, gid
  me[ '%limiter-by-uid' ][ uid ]  = R
  return R

#-----------------------------------------------------------------------------------------------------------
@get_remaining_token_count = ( me, uid ) ->
  return ( @fetch_limiter me, uid ).getTokensRemaining()


#===========================================================================================================
# DESCRIPTIONS
#-----------------------------------------------------------------------------------------------------------
@description_matcher = ///
  ( [ 0-9 ]+ ) \s+ hits? \s+
  per \s+ ( second | minute | hour | day ) \s+
  ( with (?: out )? ) \s+ delay ///

#-----------------------------------------------------------------------------------------------------------
@count_and_unit_from_gid = ( me, gid ) ->
  limiter_arguments = me[ 'arguments-by-gid' ][ gid ]
  throw new Error "GID #{rpr gid} unknown" unless limiter_arguments?
  [ count
    unit
    ignored ] = limiter_arguments
  return [ count, unit, ]

#-----------------------------------------------------------------------------------------------------------
@count_and_unit_from_uid = ( me, uid ) ->
  return @count_and_unit_from_gid me, @gid_from_uid me, uid

#-----------------------------------------------------------------------------------------------------------
@parse_description = ( me, description ) ->
  match = description.match @description_matcher
  throw new Error "unable to parse limiter description #{rpr description}" unless match?
  #.........................................................................................................
  [ ignored
    count
    unit
    has_delay ] = match
  #.........................................................................................................
  count     = parseInt count, 10
  has_delay = has_delay is 'without'
  #.........................................................................................................
  return [ count, unit, has_delay, ]




