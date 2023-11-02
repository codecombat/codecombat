// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let I18NEditThangTypeView;
const I18NEditModelView = require('./I18NEditModelView');
const ThangType = require('models/ThangType');

module.exports = (I18NEditThangTypeView = (function() {
  I18NEditThangTypeView = class I18NEditThangTypeView extends I18NEditModelView {
    static initClass() {
      this.prototype.id = 'i18n-thang-type-view';
      this.prototype.modelClass = ThangType;
    }

    buildTranslationList() {
      const lang = this.selectedLanguage;
      if (!this.model.hasLocalChanges()) { this.model.markToRevert(); }
      const i18n = this.model.get('i18n');
      if (i18n) {
        let extendedName, shortName, unlockLevelName;
        const name = this.model.get('name');
        this.wrapRow('Name', ['name'], name, i18n[lang] != null ? i18n[lang].name : undefined, []);
        this.wrapRow('Description', ['description'], this.model.get('description'), i18n[lang] != null ? i18n[lang].description : undefined, [], 'markdown');
        if (extendedName = this.model.get('extendedName')) {
          this.wrapRow('Extended Hero Name', ['extendedName'], extendedName, i18n[lang] != null ? i18n[lang].extendedName : undefined, []);
        }
        if (shortName = this.model.get('shortName')) {
          this.wrapRow('Short Hero Name', ['shortName'], shortName, i18n[lang] != null ? i18n[lang].shortName : undefined, []);
        }
        if (unlockLevelName = this.model.get('unlockLevelName')) {
          return this.wrapRow('Unlock Level Name', ['unlockLevelName'], unlockLevelName, i18n[lang] != null ? i18n[lang].unlockLevelName : undefined, []);
        }
      }
    }
  };
  I18NEditThangTypeView.initClass();
  return I18NEditThangTypeView;
})());
