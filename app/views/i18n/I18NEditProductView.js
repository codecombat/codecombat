/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let I18NEditProductView;
const I18NEditModelView = require('./I18NEditModelView');
const Product = require('models/Product');
const deltasLib = require('core/deltas');
const Patch = require('models/Patch');
const Patches = require('collections/Patches');
const PatchModal = require('views/editor/PatchModal');

// TODO: Apply these changes to all i18n views if it proves to be more reliable

module.exports = (I18NEditProductView = (function() {
  I18NEditProductView = class I18NEditProductView extends I18NEditModelView {
    static initClass() {
      this.prototype.id = "i18n-edit-product-view";
      this.prototype.modelClass = Product;
    }

    buildTranslationList() {
      let i18n;
      const lang = this.selectedLanguage;

      // name, description
      if (i18n = this.model.get('i18n')) {
        let description, name;
        if (name = this.model.get('displayName')) {
          this.wrapRow('Product short name', ['displayName'], name, i18n[lang] != null ? i18n[lang].displayName : undefined, []);
        }
        if (description = this.model.get('displayDescription')) {
          return this.wrapRow('Product description', ['displayDescription'], description, i18n[lang] != null ? i18n[lang].displayDescription : undefined, []);
        }
      }
    }
  };
  I18NEditProductView.initClass();
  return I18NEditProductView;
})());

