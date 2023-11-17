/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const Course = require('models/Course');
const Level = require('models/Level');
const LevelSession = require('models/LevelSession');
const ImageGalleryModal = require('views/play/level/modal/ImageGalleryModal');
const ProgressView = require('views/play/level/modal/ProgressView');
const factories = require('test/app/factories');
const utils = require('core/utils');

describe('ImageGalleryModal', function() {
  let modal = null;

  beforeEach(function(done) {
    modal = new ImageGalleryModal();
    modal.render();
    return _.defer(done);
  });

  it('(demo)', () => jasmine.demoModal(modal));

  it('shows a list of images', () => expect(modal.$('img').length).toBeGreaterThan(16));

  describe('clicking an image', function() {
    beforeEach(function(done) {
      this.clickedImage = modal.$('li:nth-child(5)').click();
      this.clickedImagePath = this.clickedImage.data('portrait-url');
      this.clickedImageUrl = utils.pathToUrl(this.clickedImagePath);
      this.clickedImageTag = '<img src="' + this.clickedImageUrl + '"/>';
      return _.defer(done);
    });

    it('highlights the chosen image', () => expect(modal.$('li:nth-child(5)').hasClass('selected')).toBe(true));

    return it('displays the URL/image tags in the Copy section', function() {
      expect(modal.$('.image-url').text()).toBe(this.clickedImageUrl);
      return expect(modal.$('.image-tag').text()).toBe(this.clickedImageTag);
    });
  });

  return describe("How to Copy/Paste section", function() {
    const userAgents = {
      windows: 'Mozilla/5.0 (Windows NT 6.3; Trident/7.0; rv:11.0) like Gecko',
      mac: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/52.0.2743.116 Safari/537.36'
    };

    it('Shows Windows shortcuts to Windows users', function(done) {
      spyOn(utils, 'userAgent').and.callFake(() => userAgents.windows);
      modal.render();
      // This test is a little fragile — Only works if the text node is an immediate child to .windows-only
      expect(modal.$('.how-to-copy-paste :not(.hidden)').text()).toMatch(/Control|Ctrl/i);
      expect(modal.$('.how-to-copy-paste :not(.hidden)').text()).not.toMatch(/Command|Cmd/i);
      this.clickedImage = modal.$('li:nth-child(5)').click();
      return _.defer(function() {
        expect(modal.$('.how-to-copy-paste :not(.hidden)').text()).toMatch(/Control|Ctrl/i);
        expect(modal.$('.how-to-copy-paste :not(.hidden)').text()).not.toMatch(/Command|Cmd/i);
        return done();
      });
    });

    return it('Shows Mac shortcuts to Mac users', function(done) {
      spyOn(utils, 'userAgent').and.callFake(() => userAgents.mac);
      modal.render();
      // This test is a little fragile — Only works if the text node is an immediate child to .mac-only
      expect(modal.$('.how-to-copy-paste :not(.hidden)').text()).toMatch(/Command|Cmd/i);
      expect(modal.$('.how-to-copy-paste :not(.hidden)').text()).not.toMatch(/Control|Ctrl/i);
      this.clickedImage = modal.$('li:nth-child(5)').click();
      return _.defer(function() {
        expect(modal.$('.how-to-copy-paste :not(.hidden)').text()).toMatch(/Command|Cmd/i);
        expect(modal.$('.how-to-copy-paste :not(.hidden)').text()).not.toMatch(/Control|Ctrl/i);
        return done();
      });
    });
  });
});
