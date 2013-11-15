


############################################################################################################
TRM                       = require 'coffeenode-trm'
rpr                       = TRM.rpr.bind TRM
badge                     = 'LIMIT/tests'
log                       = TRM.get_logger 'plain',   badge
info                      = TRM.get_logger 'info',    badge
whisper                   = TRM.get_logger 'whisper', badge
alert                     = TRM.get_logger 'alert',   badge
debug                     = TRM.get_logger 'debug',   badge
warn                      = TRM.get_logger 'warn',    badge
help                      = TRM.get_logger 'help',    badge
echo                      = TRM.echo.bind TRM
#...........................................................................................................
suspend                   = require 'coffeenode-suspend'
after                     = suspend.after
eventually                = suspend.eventually
every                     = suspend.every
#...........................................................................................................
LIMIT                  = require '..'


#-----------------------------------------------------------------------------------------------------------
t0          = new Date() / 1000
hit_count   = 0
miss_count  = 0
perform = ( lmt ) ->
  LIMIT.permesso lmt, uid, ( error, ok, ms_to_wait ) ->
    dt = ( new Date() / 1000 ) - t0
    if ok
      hit_count  += 1
      hits_per_s  = ( hit_count / dt ).toFixed 4
      info uid, hits_per_s, ms_to_wait
    else
      miss_count   += 1
      misses_per_s  = ( miss_count / dt ).toFixed 4
      warn uid, misses_per_s, ms_to_wait



# info '2 hits per second without delay'.match description_matcher
# info '3 hits per hour with delay'.match description_matcher

options = O =
  'gid-by-uid':           {}
  'description-by-gid':
    'spam':                 '0 hits per day without delay'
    # 'default':              '3 hits per hour with delay'
    'default':              '60 hits per minute with delay'
    'premium':              '10 hits per second with delay'


lmt = LIMIT.new_registry O
LIMIT.new_user lmt, 'king', 'premium'
uid = 'king'
uid = 'some-uid'
every 0.05, -> perform lmt



