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
let I18NEditComponentView;
import I18NEditModelView from './I18NEditModelView';
import LevelComponent from 'models/LevelComponent';

export default I18NEditComponentView = (function() {
  I18NEditComponentView = class I18NEditComponentView extends I18NEditModelView {
    static initClass() {
      this.prototype.id = 'i18n-edit-component-view';
      this.prototype.modelClass = LevelComponent;
    }

    buildTranslationList() {
      let context, i18n, key, value;
      const lang = this.selectedLanguage;

      const propDocs = this.model.get('propertyDocumentation');

      for (let propDocIndex = 0; propDocIndex < propDocs.length; propDocIndex++) {

        //- Component property descriptions
        var description, path, progLang;
        var propDoc = propDocs[propDocIndex];
        if (i18n = propDoc.i18n) {
          var shortDescription;
          path = ['propertyDocumentation', propDocIndex];
          this.wrapRow(`${propDoc.name} name value`, ['name'], propDoc.name, i18n[lang] != null ? i18n[lang].name : undefined, path);
          if (_.isObject(propDoc.description)) {
            for (progLang in propDoc.description) {
              description = propDoc.description[progLang];
              this.wrapRow(`${propDoc.name} description (${progLang})`, ['description', progLang], description, __guard__(i18n[lang] != null ? i18n[lang].description : undefined, x => x[progLang]), path, 'markdown');
            }
          } else if (_.isString(propDoc.description)) {
            this.wrapRow(`${propDoc.name} description`, ['description'], propDoc.description, i18n[lang] != null ? i18n[lang].description : undefined, path, 'markdown');
          }
          if (_.isObject(propDoc.shortDescription)) {
            for (progLang in propDoc.shortDescription) {
              shortDescription = propDoc.shortDescription[progLang];
              this.wrapRow(`${propDoc.name} shortDescription (${progLang})`, ['shortDescription', progLang], shortDescription, __guard__(i18n[lang] != null ? i18n[lang].shortDescription : undefined, x1 => x1[progLang]), path, 'markdown');
            }
          } else if (_.isString(propDoc.shortDescription)) {
            this.wrapRow(`${propDoc.name} shortDescription`, ['shortDescription'], propDoc.shortDescription, i18n[lang] != null ? i18n[lang].shortDescription : undefined, path, 'markdown');
          }
          if (context = propDoc.context) {
            for (key in context) {
              value = context[key];
              this.wrapRow(`${propDoc.name} context value`, ['context', key], value, __guard__(i18n[lang] != null ? i18n[lang].context : undefined, x2 => x2[key]), path);
            }
          }
        }

        //- Component return value descriptions
        if (i18n = propDoc.returns != null ? propDoc.returns.i18n : undefined) {
          path = ['propertyDocumentation', propDocIndex, 'returns'];
          var d = propDoc.returns.description;
          if (_.isObject(d)) {
            for (progLang in d.description) {
              description = d.description[progLang];
              this.wrapRow(`${propDoc.name} return val (${progLang})`, ['description', progLang], description, i18n[lang].description != null ? i18n[lang].description[progLang] : undefined, path, 'markdown');
            }
          } else if (_.isString(d)) {
            this.wrapRow(`${propDoc.name} return val`, ['description'], d, i18n[lang] != null ? i18n[lang].description : undefined, path, 'markdown');
          }
        }

        //- Component argument descriptions
        if (propDoc.args) {
          for (var argIndex = 0; argIndex < propDoc.args.length; argIndex++) {
            var argDoc = propDoc.args[argIndex];
            if (i18n = argDoc.i18n) {
              path = ['propertyDocumentation', propDocIndex, 'args', argIndex];
              if (_.isObject(argDoc.description)) {
                for (progLang in argDoc.description) {
                  description = argDoc.description[progLang];
                  this.wrapRow(`${propDoc.name} arg description ${argDoc.name} (${progLang})`, ['description', progLang], description, __guard__(i18n[lang] != null ? i18n[lang].description : undefined, x3 => x3[progLang]), path, 'markdown');
                }
              } else if (_.isString(argDoc.description)) {
                this.wrapRow(`${propDoc.name} arg description ${argDoc.name}`, ['description'], argDoc.description, i18n[lang] != null ? i18n[lang].description : undefined, path, 'markdown');
              }
            }
          }
        }
      }

      // Code context
      i18n = this.model.get("i18n");
      context = this.model.get("context");
      if (i18n && context) {
        return (() => {
          const result = [];
          for (key in context) {
            value = context[key];
            result.push(this.wrapRow("Code context value", ['context', key], value, __guard__(i18n[lang] != null ? i18n[lang].context : undefined, x4 => x4[key]), []));
          }
          return result;
        })();
      }
    }
  };
  I18NEditComponentView.initClass();
  return I18NEditComponentView;
})();

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}