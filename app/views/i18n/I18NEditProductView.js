// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let I18NEditProductView;
import I18NEditModelView from './I18NEditModelView';
import Product from 'models/Product';
import deltasLib from 'core/deltas';
import Patch from 'models/Patch';
import Patches from 'collections/Patches';
import PatchModal from 'views/editor/PatchModal';

// TODO: Apply these changes to all i18n views if it proves to be more reliable

export default I18NEditProductView = (function() {
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
})();

