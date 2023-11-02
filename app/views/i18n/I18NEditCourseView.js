// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let I18NEditCourseView;
const I18NEditModelView = require('./I18NEditModelView');
const Course = require('models/Course');
const deltasLib = require('core/deltas');
const Patch = require('models/Patch');
const Patches = require('collections/Patches');
const PatchModal = require('views/editor/PatchModal');

// TODO: Apply these changes to all i18n views if it proves to be more reliable

module.exports = (I18NEditCourseView = (function() {
  I18NEditCourseView = class I18NEditCourseView extends I18NEditModelView {
    static initClass() {
      this.prototype.id = "i18n-edit-course-view";
      this.prototype.modelClass = Course;
    }

    buildTranslationList() {
      let i18n;
      const lang = this.selectedLanguage;

      // name, description, shortName
      if (i18n = this.model.get('i18n')) {
        let description, name;
        if (name = this.model.get('name')) {
          this.wrapRow('Course short name', ['name'], name, i18n[lang] != null ? i18n[lang].name : undefined, []);
        }
        if (description = this.model.get('description')) {
          this.wrapRow('Course description', ['description'], description, i18n[lang] != null ? i18n[lang].description : undefined, []);
        }

        // Update the duration text that appears in the curriculum guide
        const durationI18n = __guard__(this.model.get('duration'), x => x.i18n);
        if (durationI18n) {
          let inGame, total, totalTimeRange;
          if (total = this.model.get('duration').total) {
            this.wrapRow(
              'Duration Total',
              ['total'],
              total,
              durationI18n[lang] != null ? durationI18n[lang].total : undefined,
              ['duration']);
          }
          if (inGame = this.model.get('duration').inGame) {
            this.wrapRow(
              'Duration inGame',
              ['inGame'],
              inGame,
              durationI18n[lang] != null ? durationI18n[lang].inGame : undefined,
              ['duration']);
          }
          if (totalTimeRange = this.model.get('duration').totalTimeRange) {
            this.wrapRow(
              'Duration totalTimeRange',
              ['totalTimeRange'],
              totalTimeRange,
              durationI18n[lang] != null ? durationI18n[lang].totalTimeRange : undefined,
              ['duration']);
          }
        }

        const cstaStandards = this.model.get('cstaStandards') || [];
        return (() => {
          const result = [];
          for (let i = 0; i < cstaStandards.length; i++) {
            var standard = cstaStandards[i];
            i18n = standard['i18n'];
            if (i18n) {
              this.wrapRow('CSTA: Name', ['name'], standard.name, i18n[lang] != null ? i18n[lang].name : undefined, ['cstaStandards', i]);
              result.push(this.wrapRow('CSTA: Description', ['description'], standard.description, i18n[lang] != null ? i18n[lang].description : undefined, ['cstaStandards', i]));
            } else {
              result.push(undefined);
            }
          }
          return result;
        })();
      }
    }
  };
  I18NEditCourseView.initClass();
  return I18NEditCourseView;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}