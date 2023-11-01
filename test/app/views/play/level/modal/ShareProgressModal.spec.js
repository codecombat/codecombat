/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const ShareProgressModal = require('views/play/modal/ShareProgressModal');
const Course = require('models/Course');
const Level = require('models/Level');
const LevelSession = require('models/LevelSession');
const Achievements = require('collections/Achievements');

describe('ShareProgressModal', function() {
  beforeEach(() => me.clear());
  
  return describe('continue button in other languages', function() {
    let modal = null;

    beforeEach(function(done) {
      // Not sure why this isn't affecting the modal. Do I need to load the locale file?
      me.set('preferredLanguage', 'es-ES');
      // Can position testing be done? These values are zeros at runtime
      modal = new ShareProgressModal();
      modal.render();
      return _.defer(done);
    });
      
    xit('should be positioned high enough', function() {
      jasmine.demoModal(modal);
      const link = modal.$('.continue-link');
      const linkBottom = link.offset().top + link.height();
      const background = modal.$('.background-img');
      const backgroundBottom = background.offset().top + background.height();
      return expect(linkBottom).toBeLessThan(backgroundBottom - 30);
    });

    return it('(demo)', () => jasmine.demoModal(modal));
  });
});
