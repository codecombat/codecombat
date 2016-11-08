constants = require('../constants');

var timestamp = new Date().getTime(),
  email = `email${timestamp}@${timestamp}.com`,
  name = timestamp.toString(),
  password = timestamp.toString();

module.exports = {
  'Sign up': function (browser) {

    browser
      // Go to home page
      .url(constants.DOMAIN)
      .resizeWindow(1250, 900)

      // Open login modal
      .waitForApplicationLoaded()
      .click('#create-account-link')
  
      // Sign up
      .waitForModalLoaded()
      .waitForElementVisibleAndClick('.individual-path-button')
      .waitForElementVisibleAndClick('#birthday-month-input')
      .setValue('#birthday-month-input', 'January')
      .setValue('#birthday-day-input', '1')
      .setValue('#birthday-year-input', '1999')
      .pause(constants.PAUSE_TIME)
      .click('.next-button')
      .waitForElementVisible('input[name="email"]', constants.ASYNC_TIMEOUT)
      .executeAsync(function(done) {
        // If G+ or FB load in the middle of execution, they re-render the modal. This code waits for both
        // to load before continuing. TODO: Refactor code so this is unnecessary.
        check = function() {
          if(currentModal.signupState.get('facebookEnabled') && currentModal.signupState.get('gplusEnabled')) {
            done()
          }
        }
        currentModal.signupState.on('change', check);
        check();
      }, [], function(res) { if(res.error) { console.error('G+/FB wait error:', res.error) } })
      .pause(constants.PAUSE_TIME)
      .setValue('input[name="email"]', email)
      .setValue('input[name="name"]', name)
      .setValue('input[name="password"]', password)
      .click('#subscribe-input')
      .pause(constants.PAUSE_TIME*2)
      .click('#create-account-btn')
      .waitForElementVisibleAndClick('#start-btn')
      
      // Confirm we went to campaign view, navigate back to home
      .waitForElementVisible('#logout-button', constants.ASYNC_TIMEOUT * 3) // takes particularly long
      .assert.urlContains('/play')
  },
  
  'Logout': function (browser) {
    browser
      .url(constants.DOMAIN)
      .waitForViewLoaded()
      .pause(constants.PAUSE_TIME)
      .click('.dropdown-toggle')
      .waitForElementVisibleAndClick('.dropdown #logout-button')
  },
  
  'Log back in': function (browser) {
    browser
      .waitForElementVisibleAndClick('#login-link')
      .waitForElementVisible('#login-btn', constants.ASYNC_TIMEOUT)
      .setValue('input#username-or-email-input', email)
      .setValue('input#password-input', password)
      .pause(constants.PAUSE_TIME)
      .click('#login-btn')
      .waitForElementVisible('#main-nav', constants.ASYNC_TIMEOUT)
      .pause(constants.PAUSE_TIME)
  },
  
  'Delete account': function (browser) {
    browser
      .url(`${constants.DOMAIN}/account/settings`)
      .pause(constants.PAUSE_TIME)
      .waitForViewLoaded()
      .waitForElementVisible('#delete-account-email-or-username', constants.ASYNC_TIMEOUT)
      .setValue('#delete-account-email-or-username', email)
      .setValue('#delete-account-password', password)
      .pause(constants.PAUSE_TIME)
      .click('#delete-account-btn')
      .waitForElementVisibleAndClick('#confirm-button')
      .pause(constants.PAUSE_TIME*2)
      .end();
  }
};
