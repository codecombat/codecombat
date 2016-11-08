constants = require('../constants');

exports.command = function() {
  return this
    .timeoutsAsyncScript(constants.ASYNC_TIMEOUT)
    .executeAsync(function(done) {
      try {
        window.currentView.supermodel.finishLoading()
          .then(function() { done(); })
          .catch(function(e) { console.error('Promise error', e); done(e); });
      }
      catch (e) {
        console.error('Caught error:', e);
        done(e);
      }
    }, [], function(result) {
      if(result.error)
        console.log('waitForViewLoaded error:', result.error)
    })
    .pause(constants.PAUSE_TIME);
};
