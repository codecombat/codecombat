/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let LegalView;
require('app/styles/legal.sass');
const RootView = require('views/core/RootView');
const template = require('templates/legal');
const Products = require('collections/Products');

module.exports = (LegalView = (function() {
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
})());
