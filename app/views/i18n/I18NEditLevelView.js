// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let I18NEditLevelView;
import I18NEditModelView from './I18NEditModelView';
import Level from 'models/Level';
import LevelComponent from 'models/LevelComponent';

export default I18NEditLevelView = (function() {
  I18NEditLevelView = class I18NEditLevelView extends I18NEditModelView {
    static initClass() {
      this.prototype.id = 'i18n-edit-level-view';
      this.prototype.modelClass = Level;
    }

    buildTranslationList() {
      let component, componentIndex, context, goal, hint, i18n, index, key, left, left1, left2, left3, left4, left5, left6, name, path, thang, thangIndex, value;
      const lang = this.selectedLanguage;

      // name, description
      if (i18n = this.model.get('i18n')) {
        let description, displayName, loadingTip, studentPlayInstructions;
        if (name = this.model.get('name')) {
          this.wrapRow('Level name', ['name'], name, i18n[lang] != null ? i18n[lang].name : undefined, []);
        }
        if (description = this.model.get('description')) {
          this.wrapRow('Level description', ['description'], description, i18n[lang] != null ? i18n[lang].description : undefined, []);
        }
        if (displayName = this.model.get('displayName')) {
          this.wrapRow('Display name', ['displayName'], displayName, i18n[lang] != null ? i18n[lang].displayName : undefined, []);
        }
        if (loadingTip = this.model.get('loadingTip')) {
          this.wrapRow('Loading tip', ['loadingTip'], loadingTip, i18n[lang] != null ? i18n[lang].loadingTip : undefined, []);
        }
        if (studentPlayInstructions = this.model.get('studentPlayInstructions')) {
          this.wrapRow('Student Play Instructions', ['studentPlayInstructions'], studentPlayInstructions, i18n[lang] != null ? i18n[lang].studentPlayInstructions : undefined, []);
        }
      }

      // goals
      const iterable = (left = this.model.get('goals')) != null ? left : [];
      for (index = 0; index < iterable.length; index++) {
        goal = iterable[index];
        if (i18n = goal.i18n) {
          this.wrapRow('Goal name', ['name'], goal.name, i18n[lang] != null ? i18n[lang].name : undefined, ['goals', index]);
        }
      }

      // additional goals
      const iterable1 = (left1 = this.model.get('additionalGoals')) != null ? left1 : [];
      for (let gIndex = 0; gIndex < iterable1.length; gIndex++) {
        var goals = iterable1[gIndex];
        var iterable2 = goals.goals != null ? goals.goals : [];
        for (index = 0; index < iterable2.length; index++) {
          goal = iterable2[index];
          if (i18n = goal.i18n) {
            this.wrapRow('Additional Goal name', ['name'], goal.name, i18n[lang] != null ? i18n[lang].name : undefined, ['additionalGoals', gIndex, 'goals', index]);
          }
        }
      }

      // documentation
      const iterable3 = (left2 = __guard__(this.model.get('documentation'), x => x.specificArticles)) != null ? left2 : [];
      for (index = 0; index < iterable3.length; index++) {
        var doc = iterable3[index];
        if (i18n = doc.i18n) {
          this.wrapRow('Guide article name', ['name'], doc.name, i18n[lang] != null ? i18n[lang].name : undefined, ['documentation', 'specificArticles', index]);
          this.wrapRow(`'${doc.name}' body`, ['body'], doc.body, i18n[lang] != null ? i18n[lang].body : undefined, ['documentation', 'specificArticles', index], 'markdown');
        }
      }

      // hints
      const iterable4 = (left3 = __guard__(this.model.get('documentation'), x1 => x1.hints)) != null ? left3 : [];
      for (index = 0; index < iterable4.length; index++) {
        hint = iterable4[index];
        if (i18n = hint.i18n) {
          name = `Hint ${index+1}`;
          this.wrapRow(`'${name}' body`, ['body'], hint.body, i18n[lang] != null ? i18n[lang].body : undefined, ['documentation', 'hints', index], 'markdown');
        }
      }
      const iterable5 = (left4 = __guard__(this.model.get('documentation'), x2 => x2.hintsB)) != null ? left4 : [];
      for (index = 0; index < iterable5.length; index++) {
        hint = iterable5[index];
        if (i18n = hint.i18n) {
          name = `Hint ${index+1}`;
          this.wrapRow(`'${name}' body`, ['body'], hint.body, i18n[lang] != null ? i18n[lang].body : undefined, ['documentation', 'hints', index], 'markdown');
        }
      }

      // sprite dialogues
      const iterable6 = (left5 = this.model.get('scripts')) != null ? left5 : [];
      for (let scriptIndex = 0; scriptIndex < iterable6.length; scriptIndex++) {
        var script = iterable6[scriptIndex];
        var iterable7 = script.noteChain != null ? script.noteChain : [];
        for (var noteGroupIndex = 0; noteGroupIndex < iterable7.length; noteGroupIndex++) {
          var noteGroup = iterable7[noteGroupIndex];
          if (!noteGroup) { continue; }
          var iterable8 = noteGroup.sprites != null ? noteGroup.sprites : [];
          for (var spriteCommandIndex = 0; spriteCommandIndex < iterable8.length; spriteCommandIndex++) {
            var spriteCommand = iterable8[spriteCommandIndex];
            var pathPrefix = ['scripts', scriptIndex, 'noteChain', noteGroupIndex, 'sprites', spriteCommandIndex, 'say'];

            if (i18n = spriteCommand.say != null ? spriteCommand.say.i18n : undefined) {
              if (spriteCommand.say.text) {
                this.wrapRow('Sprite text', ['text'], spriteCommand.say.text, i18n[lang] != null ? i18n[lang].text : undefined, pathPrefix, 'markdown');
              }
              if (spriteCommand.say.blurb) {
                this.wrapRow('Sprite blurb', ['blurb'], spriteCommand.say.blurb, i18n[lang] != null ? i18n[lang].blurb : undefined, pathPrefix);
              }
            }

            var iterable9 = (spriteCommand.say != null ? spriteCommand.say.responses : undefined) != null ? (spriteCommand.say != null ? spriteCommand.say.responses : undefined) : [];
            for (var responseIndex = 0; responseIndex < iterable9.length; responseIndex++) {
              var response = iterable9[responseIndex];
              if (i18n = response.i18n) {
                this.wrapRow('Response button', ['text'], response.text, i18n[lang] != null ? i18n[lang].text : undefined, pathPrefix.concat(['responses', responseIndex]));
              }
            }
          }
        }
      }

      // victory modal
      if (i18n = __guard__(this.model.get('victory'), x3 => x3.i18n)) {
        this.wrapRow('Victory text', ['body'], this.model.get('victory').body, i18n[lang] != null ? i18n[lang].body : undefined, ['victory'], 'markdown');
      }

      // code comments
      const iterable10 = (left6 = this.model.get('thangs')) != null ? left6 : [];
      for (thangIndex = 0; thangIndex < iterable10.length; thangIndex++) {
        thang = iterable10[thangIndex];
        var iterable11 = thang.components != null ? thang.components : [];
        for (componentIndex = 0; componentIndex < iterable11.length; componentIndex++) {
          component = iterable11[componentIndex];
          if (!Array.from(LevelComponent.ProgrammableIDs).includes(component.original)) { continue; }
          var object = (component.config != null ? component.config.programmableMethods : undefined) != null ? (component.config != null ? component.config.programmableMethods : undefined) : {};
          for (var methodName in object) {
            var method = object[methodName];
            if ((i18n = method.i18n) && (context = method.context)) {
              for (key in context) {
                value = context[key];
                path = ['thangs', thangIndex, 'components', componentIndex, 'config', 'programmableMethods', methodName];
                this.wrapRow('Code comment', ['context', key], value, __guard__(i18n[lang] != null ? i18n[lang].context : undefined, x4 => x4[key]), path);
              }
            }
          }
        }
      }

      // code comments
      return (() => {
        let left7;
        const result = [];
        const iterable12 = (left7 = this.model.get('thangs')) != null ? left7 : [];
        for (thangIndex = 0; thangIndex < iterable12.length; thangIndex++) {
          thang = iterable12[thangIndex];
          result.push((() => {
            const result1 = [];
            const iterable13 = thang.components != null ? thang.components : [];
            for (componentIndex = 0; componentIndex < iterable13.length; componentIndex++) {
              component = iterable13[componentIndex];
              if (component.original !== LevelComponent.RefereeID) { continue; }
              if ((i18n = component.config != null ? component.config.i18n : undefined) && (context = component.config.context)) {
                result1.push((() => {
                  const result2 = [];
                  for (key in context) {
                    value = context[key];
                    path = ['thangs', thangIndex, 'components', componentIndex, 'config'];
                    result2.push(this.wrapRow('Referee context string', ['context', key], value, __guard__(i18n[lang] != null ? i18n[lang].context : undefined, x5 => x5[key]), path));
                  }
                  return result2;
                })());
              } else {
                result1.push(undefined);
              }
            }
            return result1;
          })());
        }
        return result;
      })();
    }
  };
  I18NEditLevelView.initClass();
  return I18NEditLevelView;
})();

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}