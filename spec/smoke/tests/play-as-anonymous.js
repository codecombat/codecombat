constants = require('../constants');

module.exports = {
  'Go to dungeon campaign': function (browser) {
    browser
      .url(constants.DOMAIN + '/play/dungeon')
      .resizeWindow(1250, 900)
      .waitForApplicationLoaded()
      .setPlayerVolume(0)
  },

  'Go to level view for Dungeons of Kithgard': function (browser) {
    browser
      .click('a[data-level-slug="dungeons-of-kithgard"]')
      .pause(constants.PAUSE_TIME)
      .click('.start-level')
      .pause(constants.PAUSE_TIME)
      .waitForModalLoaded()
      .waitForElementVisibleAndClick('#confirm-button')
      .waitForElementVisibleAndClick('.btn.equip-item')
      .click('#play-level-button')
      .pause(constants.PAUSE_TIME)
  },

  'Play Dungeons of Kithgard': function (browser) {
    browser
      .waitForElementVisibleAndClick('button.start-level-button')
      .keys([browser.Keys.ESCAPE])
      .pause(constants.PAUSE_TIME)
      .keys('hero.moveDown()\nhero.moveRight()\n')
      .pause(constants.PAUSE_TIME)
      .click('.cast-button')
      .pause(constants.PAUSE_TIME)
      .waitForElementVisibleAndClick('.done-button')
  },
  
  'Go through victory modal, check that Gems in the Deep is unlocked': function (browser) {
    browser
      .waitForModalLoaded()
      .click('#continue-button')
      .pause(constants.PAUSE_TIME)
      .waitForElementVisible('a[data-level-slug="gems-in-the-deep"]', constants.ASYNC_TIMEOUT)
      .pause(constants.PAUSE_TIME)
      .end()
  }
}
