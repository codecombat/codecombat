constants = require('../constants');

exports.command = function(volume) {
  return this
    .timeoutsAsyncScript(constants.ASYNC_TIMEOUT)
    .executeAsync(function(volume, done) {
      window.me.set('volume', volume)
      createjs.Sound.setVolume(volume)
      done()
    }, [volume], function(result) {
      if(result.error)
        console.log('setPlayerVolume error:', result.error, result)
    })
};
