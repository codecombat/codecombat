// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS104: Avoid inline assignments
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let I18NEditPollView;
const I18NEditModelView = require('./I18NEditModelView');
const Poll = require('models/Poll');

module.exports = (I18NEditPollView = (function() {
  I18NEditPollView = class I18NEditPollView extends I18NEditModelView {
    static initClass() {
      this.prototype.id = "i18n-edit-poll-view";
      this.prototype.modelClass = Poll;
    }

    buildTranslationList() {
      let i18n;
      const lang = this.selectedLanguage;

      // name, description
      if (i18n = this.model.get('i18n')) {
        let description, name;
        if (name = this.model.get('name')) {
          this.wrapRow("Poll name", ['name'], name, i18n[lang] != null ? i18n[lang].name : undefined, []);
        }
        if (description = this.model.get('description')) {
          this.wrapRow("Poll description", ['description'], description, i18n[lang] != null ? i18n[lang].description : undefined, []);
        }
      }

      // answers
      return (() => {
        let left;
        const result = [];
        const iterable = (left = this.model.get('answers')) != null ? left : [];
        for (let index = 0; index < iterable.length; index++) {
          var answer = iterable[index];
          if (i18n = answer.i18n) {
            result.push(this.wrapRow('Answer', ['text'], answer.text, i18n[lang] != null ? i18n[lang].text : undefined, ['answers', index]));
          } else {
            result.push(undefined);
          }
        }
        return result;
      })();
    }
  };
  I18NEditPollView.initClass();
  return I18NEditPollView;
})());
