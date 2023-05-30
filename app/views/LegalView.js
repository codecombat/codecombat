// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let LegalView;
import 'app/styles/legal.sass';
import RootView from 'views/core/RootView';
import template from 'templates/legal';
import Products from 'collections/Products';

export default LegalView = (function() {
  LegalView = class LegalView extends RootView {
    static initClass() {
      this.prototype.id = 'legal-view';
      this.prototype.template = template;
    }

    initialize() {
      this.products = new Products();
      return this.supermodel.loadCollection(this.products, 'products');
    }
  };
  LegalView.initClass();
  return LegalView;
})();
