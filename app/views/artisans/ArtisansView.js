// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ArtisansView;
import 'app/styles/artisans/artisans-view.sass';
import RootView from 'views/core/RootView';
import template from 'app/templates/artisans/artisans-view';

export default ArtisansView = (function() {
  ArtisansView = class ArtisansView extends RootView {
    static initClass() {
      this.prototype.template = template;
      this.prototype.id = 'artisans-view';
    }
  };
  ArtisansView.initClass();
  return ArtisansView;
})();
