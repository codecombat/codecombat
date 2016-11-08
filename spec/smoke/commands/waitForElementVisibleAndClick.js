constants = require('../constants');

exports.command = function(selector) {
  return this
    .waitForElementVisible(selector, constants.ASYNC_TIMEOUT)
    .pause(constants.PAUSE_TIME)
    .click(selector);
};
