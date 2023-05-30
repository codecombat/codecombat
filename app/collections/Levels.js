/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let LevelCollection;
const CocoCollection = require('collections/CocoCollection');
const Level = require('models/Level');
const utils = require('core/utils');
const aetherUtils = require('lib/aether_utils');

module.exports = (LevelCollection = (function() {
  LevelCollection = class LevelCollection extends CocoCollection {
    static initClass() {
      this.prototype.url = '/db/level';
      this.prototype.model = Level;
    }

    fetchForClassroom(classroomID, options) {
      if (options == null) { options = {}; }
      options.url = `/db/classroom/${classroomID}/levels`;
      return this.fetch(options);
    }

    fetchForClassroomAndCourse(classroomID, courseID, options) {
      if (options == null) { options = {}; }
      options.url = `/db/classroom/${classroomID}/courses/${courseID}/levels`;
      return this.fetch(options);
    }

    fetchForCampaign(campaignSlug, options) {
      if (options == null) { options = {}; }
      options.url = `/db/campaign/${campaignSlug}/levels`;
      return this.fetch(options);
    }

    getSolutionsMap(languages) {
      return this.models.reduce((map, level) => {
        const targetLangs = level.get('primerLanguage') ? [level.get('primerLanguage')] : languages;
        const allSolutions = _.filter(level.getSolutions(), s => !s.testOnly);
        const solutions = this.constructor.getSolutionsHelper({ targetLangs, allSolutions });
        map[level.get('original')] = solutions != null ? solutions.map(s => ({source: this.fingerprint(s.source, s.language), description: s.description})) : undefined;
        return map;
      }
      , {});
    }

    static getSolutionsHelper({ targetLangs, allSolutions }) {
      const solutions = [];
      for (var lang of Array.from(targetLangs)) {
        var s;
        if (lang === 'html') {
          for (s of Array.from(allSolutions)) {
            if (s.language === 'html') {
              var strippedSource = utils.extractPlayerCodeTag(s.source || '');
              if (strippedSource) { s.source = strippedSource; }
              solutions.push(s);
            }
          }
        } else if ((lang !== 'javascript') && !_.find(allSolutions, {language: lang})) {
          for (s of Array.from(allSolutions)) {
            if (s.language === 'javascript') {
              s.language = lang;
              s.source = aetherUtils.translateJS(s.source, lang);
              solutions.push(s);
            }
          }
        } else {
          for (s of Array.from(allSolutions)) {
            if (s.language === lang) {
              solutions.push(s);
            }
          }
        }
      }
      return solutions;
    }

    fingerprint(code, language) {
      // Add a zero-width-space at the end of every comment line
      return this.constructor.fingerprintHelper(code, language);
    }

    static fingerprintHelper(code, language) {
      switch (language) {
        case ['javascript', 'java', 'cpp']: return code.replace(/^(\/\/.*)/gm, "$1​");
        case 'lua': return code.replace(/^(--.*)/gm, "$1​");
        case 'html': return code.replace(/^(<!--.*)-->/gm, "$1​-->");
        default: return code.replace(/^(#.*)/gm, "$1​");
      }
    }
  };
  LevelCollection.initClass();
  return LevelCollection;
})());
