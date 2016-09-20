WAIT_TIMEOUT = 8000;

// TODO: Refactor into shared file
switch (process.env.COCO_SMOKE_DOMAIN) {
  case "local":
    DOMAIN = 'http://localhost:3000';
    break;
  case "next":
    DOMAIN = 'http://next.codecombat.com';
    break;
  case "staging":
    DOMAIN = 'http://staging.codecombat.com';
    break;
  case "prod":
    DOMAIN = 'https://codecombat.com';
    break;
  default:
    DOMAIN = 'http://localhost:3000';
}

var timestamp = new Date().getTime(),
  email = `email${timestamp}@${timestamp}.com`,
  name = timestamp.toString(),
  password = timestamp.toString();

module.exports = {
  'Sign up': function (browser) {

    browser
      // Go to home page
      .url(DOMAIN)
      .resizeWindow(1250, 900)

      // Open login modal
      .executeAsync(function(done) { window.currentView.supermodel.finishLoading.then(done); })
      .click('#create-account-link')
  
      // Sign up
      .waitForElementVisible('.individual-path-button', WAIT_TIMEOUT)
      .click('.individual-path-button')
      .waitForElementVisible('#birthday-month-input', WAIT_TIMEOUT)
      .setValue('#birthday-month-input', 'January')
      .setValue('#birthday-day-input', '1')
      .setValue('#birthday-year-input', '1999')
      .click('.next-button')
      .waitForElementVisible('input[name="email"]', WAIT_TIMEOUT)
      .setValue('input[name="email"]', email)
      .setValue('input[name="name"]', name)
      .setValue('input[name="password"]', password)
      .click('#subscribe-input')
      .pause(100) // Sometimes create account button does not get clicked 
      .click('#create-account-btn')
      .waitForElementVisible('#start-btn', WAIT_TIMEOUT)
      .click('#start-btn')
  
      // Confirm we went to campaign view, navigate back to home
      .waitForElementVisible('#logout-button', WAIT_TIMEOUT * 3) // takes particularly long
      .assert.urlContains('/play')
  },
  
  'Logout': function (browser) {
    browser
      .url(DOMAIN)
      .executeAsync(function (done) {
        window.currentView.supermodel.finishLoading.then(done);
      })
      .click('.dropdown-toggle')
      .waitForElementVisible('.dropdown #logout-button', WAIT_TIMEOUT)
      .click('.dropdown #logout-button')
  },

  'Log back in': function (browser) {
    browser
      // Log back in
      .waitForElementVisible('#login-link', WAIT_TIMEOUT)
      .click('#login-link')
      .waitForElementVisible('#login-btn', WAIT_TIMEOUT)
      .setValue('input#username-or-email-input', email)
      .setValue('input#password-input', password)
      .click('#login-btn')
      .pause(100)
      .waitForElementVisible('#main-nav', WAIT_TIMEOUT)
  },
  
  'Delete account': function (browser) {
    browser
      // Delete account
      .url(`${DOMAIN}/account/settings`)
      .pause(100)
      .executeAsync(function(done) { window.currentView.supermodel.finishLoading.then(done); })
      .waitForElementVisible('#delete-account-email-or-username', WAIT_TIMEOUT)
      .setValue('#delete-account-email-or-username', email)
      .setValue('#delete-account-password', password)
      .click('#delete-account-btn')
      .waitForElementVisible('#confirm-button', WAIT_TIMEOUT)
      .click('#confirm-button')
      .end();
  }
};


