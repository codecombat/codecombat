// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let Achievement;
const CocoModel = require('./CocoModel');
const utils = require('../core/utils');

module.exports = (Achievement = (function() {
  Achievement = class Achievement extends CocoModel {
    static initClass() {
      this.className = 'Achievement';
      this.schema = require('schemas/models/achievement');
      this.prototype.urlRoot = '/db/achievement';
      this.prototype.editableByArtisans = true;
  
      this.styleMapping = {
        1: 'achievement-wood',
        2: 'achievement-stone',
        3: 'achievement-silver',
        4: 'achievement-gold',
        5: 'achievement-diamond'
      };
  
      this.defaultImageURL = '/images/achievements/default.png';
    }

    isRepeatable() {
      return (this.get('proportionalTo') != null);
    }

    getExpFunction() {
      const func = this.get('function', true);
      if (func.kind in utils.functionCreators) { return utils.functionCreators[func.kind](func.parameters); }
    }

    save() {
      this.populateI18N();
      return super.save(...arguments);
    }

    getStyle() { return Achievement.styleMapping[this.get('difficulty', true)]; }

    getImageURL() {
      if (this.get('icon')) { return '/file/' + this.get('icon'); } else { return Achievement.defaultImageURL; }
    }

    hasImage() { return (this.get('icon') != null); }

    // TODO Could cache the default icon separately
    cacheLockedImage() {
      if (this.lockedImageURL) { return this.lockedImageURL; }
      const canvas = document.createElement('canvas');
      const image = new Image;
      image.src = this.getImageURL();
      const defer = $.Deferred();
      image.onload = () => {
        canvas.width = image.width;
        canvas.height = image.height;
        const context = canvas.getContext('2d');
        context.drawImage(image, 0, 0);
        let imgData = context.getImageData(0, 0, canvas.width, canvas.height);
        imgData = utils.grayscale(imgData);
        context.putImageData(imgData, 0, 0);
        this.lockedImageURL = canvas.toDataURL();
        return defer.resolve(this.lockedImageURL);
      };
      return defer;
    }

    getLockedImageURL() { return this.lockedImageURL; }

    i18nName() { return utils.i18n(this.attributes, 'name'); }

    i18nDescription() { return utils.i18n(this.attributes, 'description'); }
  };
  Achievement.initClass();
  return Achievement;
})());
