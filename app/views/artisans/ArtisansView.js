/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ArtisansView;
require('app/styles/artisans/artisans-view.sass');
const RootView = require('views/core/RootView');
const template = require('app/templates/artisans/artisans-view');

module.exports = (ArtisansView = (function() {
  ArtisansView = class ArtisansView extends RootView {
    static initClass() {
      this.prototype.template = template;
      this.prototype.id = 'artisans-view';
    }
  };
  ArtisansView.initClass();
  return ArtisansView;
})());
