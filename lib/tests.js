(function() {
  var LIMIT, O, TRM, after, alert, badge, debug, echo, eventually, every, help, hit_count, info, lmt, log, miss_count, options, perform, rpr, suspend, t0, uid, warn, whisper;

  TRM = require('coffeenode-trm');

  rpr = TRM.rpr.bind(TRM);

  badge = 'LIMIT/tests';

  log = TRM.get_logger('plain', badge);

  info = TRM.get_logger('info', badge);

  whisper = TRM.get_logger('whisper', badge);

  alert = TRM.get_logger('alert', badge);

  debug = TRM.get_logger('debug', badge);

  warn = TRM.get_logger('warn', badge);

  help = TRM.get_logger('help', badge);

  echo = TRM.echo.bind(TRM);

  suspend = require('coffeenode-suspend');

  after = suspend.after;

  eventually = suspend.eventually;

  every = suspend.every;

  LIMIT = require('..');

  t0 = new Date() / 1000;

  hit_count = 0;

  miss_count = 0;

  perform = function(lmt) {
    return LIMIT.permesso(lmt, uid, function(error, ok, ms_to_wait) {
      var dt, hits_per_s, misses_per_s;
      dt = (new Date() / 1000) - t0;
      if (ok) {
        hit_count += 1;
        hits_per_s = (hit_count / dt).toFixed(4);
        return info(uid, hits_per_s, ms_to_wait);
      } else {
        miss_count += 1;
        misses_per_s = (miss_count / dt).toFixed(4);
        return warn(uid, misses_per_s, ms_to_wait);
      }
    });
  };

  options = O = {
    'gid-by-uid': {},
    'description-by-gid': {
      'spam': '0 hits per day without delay',
      'default': '60 hits per minute with delay',
      'premium': '10 hits per second with delay'
    }
  };

  lmt = LIMIT.new_registry(O);

  LIMIT.new_user(lmt, 'king', 'premium');

  uid = 'king';

  uid = 'some-uid';

  every(0.05, function() {
    return perform(lmt);
  });

}).call(this);
/****generated by https://github.com/loveencounterflow/larq****/