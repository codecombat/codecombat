constants = require('../constants');

exports.command = function(callback) {
  return this
    .timeoutsAsyncScript(constants.ASYNC_TIMEOUT * 4) // Make it extra long for production
    .executeAsync(function(done) {

      waitForApplication = function () {
        if (window.application) { waitForCurrentView() }
        else { setTimeout(waitForApplication, 1) }
      }

      waitForCurrentView = function () { 
        if (window.currentView && window.currentView.supermodel) { waitForCurrentViewToLoad() }
        else { setTimeout(waitForCurrentView, 1) }
      }

      waitForCurrentViewToLoad = function () {
        if (window.currentView.supermodel.finished()) { done() }
        else { setTimeout(waitForCurrentViewToLoad) }
      }

      waitForApplication();
  }, [], function(result) {
      if(result.error)
        console.log('waitForApplicationLoaded error:', result.error, result)
      })
    .pause(constants.PAUSE_TIME)
};
