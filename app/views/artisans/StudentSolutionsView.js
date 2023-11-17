// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let parser, realm, StudentSolutionsView;
require('app/styles/artisans/student-solutions-view.sass');
const RootView = require('views/core/RootView');
const template = require('app/templates/artisans/student-solutions-view');
const utils = require('core/utils');

const Campaigns = require('collections/Campaigns');
const Campaign = require('models/Campaign');

const Levels = require('collections/Levels');
const Level = require('models/Level');
const LevelSessions = require('collections/LevelSessions');
const LevelComponent = require('models/LevelComponent');
const ace = require('lib/aceContainer');
const aceUtils = require('core/aceUtils');
const {createAetherOptions} = require('lib/aether_utils');
const loadAetherLanguage = require('lib/loadAetherLanguage');

if (utils.isOzaria) {
  if (typeof esper !== 'undefined') {
    ({
      realm
    } = new esper());
    parser = realm.parser.bind(realm);
  }
}

module.exports = (StudentSolutionsView = (function() {
  StudentSolutionsView = class StudentSolutionsView extends RootView {
    constructor(...args) {
      super(...args);
      this.parseSource = this.parseSource.bind(this);
      this.processASTNode = this.processASTNode.bind(this);
    }

    static initClass() {
      this.prototype.template = template;
      this.prototype.id = 'student-solutions-view';

      this.prototype.events =
        {'click #go-button': 'onClickGoButton'};

      this.prototype.levelSlug = "eagle-eye";
      this.prototype.limit = 500;
      this.prototype.languages = "python";
    }

    initialize() {
      this.validLanguages = ['python', 'javascript'];
      if (utils.isCodeCombat) {
        Promise.all(this.validLanguages.map(loadAetherLanguage)).then(() => {
          if (typeof esper !== 'undefined') {
            ({
              realm
            } = new esper());
            return this.parser = realm.parser.bind(realm);
          }
        });
      }
      this.resetLevelInfo();
      return this.resetSolutionsInfo();
    }

    resetLevelInfo() {
      this.intended = {};
      return this.defaultcode = {};
    }

    resetSolutionsInfo() {
      this.doLanguages = this.languages === 'all' ? ['javascript', 'python'] : [this.languages];
      this.stats = {};
      this.stats['javascript'] = { total: 0, errors: 0 };
      this.stats['python'] = { total: 0, errors: 0 };
      this.sessions = null;
      this.solutions = {};
      this.count = {};
      return this.errors = 0;
    }

    startFetchingData() {
      return this.getLevelInfo();
    }

    fetchSessions() {
      this.resetSolutionsInfo();
      return this.getRecentSessions(sessions => {
        if (this.destroyed) { return; }
        for (var session of Array.from(this.sessions.models)) {
          session = session.attributes;
          var lang = session.codeLanguage;
          if (!Array.from(this.doLanguages).includes(lang)) { continue; }
          this.stats[lang].total += 1;
          var src = session.code != null ? session.code['hero-placeholder'].plan : undefined;
          if (!src) {
            this.stats[lang].errors += 1;
            continue;
          }
          var ast = this.parseSource(src, lang);
          if (!ast) { continue; }
          ast = this.walkAST(ast, this.processASTNode);
          var hash = this.hashString(JSON.stringify(ast));
          if (this.count[hash] == null) { this.count[hash] = 0; }
          this.count[hash] += 1;
          if (this.solutions[hash] == null) { this.solutions[hash] = []; }
          this.solutions[hash].push(session);
        }

        let oneOffs = 0;
        const tallyFn = (result, value, key) => {
          if ((value === 1) && (oneOffs > 40)) { return result; }
          if (value === 1) { oneOffs += 1; }
          if (result[value] == null) { result[value] = []; }
          result[value].push(key);
          return result;
        };

        this.talliedHashes = _.reduce(this.count, tallyFn, {});
        this.sortedTallyCounts = _.sortBy(_.keys(this.talliedHashes), v => parseInt(v)).reverse();
        return this.render();
      });
    }

    afterRender() {
      super.afterRender();
      const editorElements = this.$el.find('.ace');
      return (() => {
        const result = [];
        for (var el of Array.from(editorElements)) {
          var lang = this.$(el).data('language');
          var editor = ace.edit(el);
          var aceSession = editor.getSession();
          var aceDoc = aceSession.getDocument();
          aceSession.setMode(aceUtils.aceEditModes[lang]);
          editor.setTheme('ace/theme/textmate');
          result.push(editor.setReadOnly(true));
        }
        return result;
      })();
    }

    getRecentSessions(doneCallback) {
      this.sessions = new LevelSessions();
      const data = {slug: this.levelSlug, limit: this.limit};
      if (this.doLanguages.length === 1) {
        data.codeLanguage = this.doLanguages[0];
      }
      return this.sessions.fetchRecentSessions({data, method: 'POST', success: doneCallback});
    }

    getLevelInfo() {
      this.level = this.supermodel.getModel(Level, this.levelSlug) || new Level({_id: this.levelSlug});
      this.supermodel.trackRequest(this.level.fetch());
      this.level.on('error', (level, error) => {
        this.level = level;
        return noty({text: `Error loading level: ${error.statusText}`, layout: 'center', type: 'error', killer: true});
      });
      if (this.level.loaded) {
        return this.onLevelLoaded(this.level);
      } else {
        return this.listenToOnce(this.level, 'sync', this.onLevelLoaded);
      }
    }

    onClickGoButton(event) {
      event.preventDefault();
      this.limit = this.$('#sessionNum').val();
      this.languages = this.$('#languageSelect').val();
      this.levelSlug = this.$('#levelSlug').val();
      return this.startFetchingData();
    }

    onLevelLoaded(level) {
      let ast, hash;
      this.resetLevelInfo();

      for (var solution of Array.from(level.getSolutions())) {
        if (!solution.source || !Array.from(this.validLanguages).includes(solution.language)) { continue; }
        ast = this.parseSource(solution.source, solution.language);
        if (!ast) { continue; }
        ast = this.walkAST(ast, this.processASTNode);
        hash = this.hashString(JSON.stringify(ast));
        this.intended[solution.language] = {hash, source: solution.source};
      }

      const defaults = this.getDefaultCode(level);
      const object = this.getDefaultCode(level);
      for (var language in object) {
        var source = object[language];
        if (!source || !Array.from(this.validLanguages).includes(language)) { continue; }
        ast = this.parseSource(source, language);
        if (!ast) { continue; }
        ast = this.walkAST(ast, this.processASTNode);
        hash = this.hashString(JSON.stringify(ast));
        this.defaultcode[language] = {hash, source};
      }
      return this.fetchSessions();
    }

    getDefaultCode(level) {

      let comp, programmableComponentOriginal, src;
      const parseTemplate = (src, context) => {
        try {
          const res = _.template(src)(context);
          return res;
        } catch (e) {
          console.warn("Template Error");
          console.log(src);
          return src;
        }
      };

      // TODO: put this into Level? if so, also use it in TeacherCourseSolutionView
      if (utils.isCodeCombat) {
        programmableComponentOriginal = '524b7b5a7fc0f6d51900000e';
      }
      const heroPlaceholder = _.find(level.get('thangs'), {id: 'Hero Placeholder'});
      if (utils.isCodeCombat) {
        comp = _.find(heroPlaceholder != null ? heroPlaceholder.components : undefined, {original: programmableComponentOriginal});
      } else {
        comp = _.find(heroPlaceholder != null ? heroPlaceholder.components : undefined, c => Array.from(LevelComponent.ProgrammableIDs).includes(c));
      }

      const programmableMethod = comp != null ? comp.config.programmableMethods.plan : undefined;
      const result = {};

      // javascript
      if (programmableMethod.source) {
        src = programmableMethod.source;
        src = parseTemplate(src, programmableMethod.context);
        result['javascript'] = src;
      }
      // non-javascript
      for (var key of Array.from(_.keys(programmableMethod.languages))) {
        if (!['python'].includes(key)) { continue; }
        src = programmableMethod.languages[key];
        src = parseTemplate(src, programmableMethod.context);
        result[key] = src;
      }

      return result;
    }

    parseSource(src, lang) {
      let ast;
      if (lang === 'python') {
        const aether = new Aether({language: 'python'});
        const tsrc = aether.transpile(src);
        ({
          ast
        } = aether);
      }
        // TODO: continue if error
        // aether.problems?
      if (lang === 'javascript') {
        try {
          ast = this.parser(src);
        } catch (e) {
          this.stats[lang].errors += 1;
          return null;
        }
      }
      return ast;
    }

    // Salvaged from dying Aether project
    walkAST(node, fn) {
      for (var key in node) {
        var child = node[key];
        if (_.isArray(child)) {
          for (var grandchild of Array.from(child)) {
            if (_.isString(grandchild != null ? grandchild.type : undefined)) {
              this.walkAST(grandchild, fn);
            }
          }
        } else if (_.isString(child != null ? child.type : undefined)) {
          this.walkAST(child, fn);
        }
      }
      return fn(node);
    }

    processASTNode(node) {
      if (node == null) { return; }
      if (node.range) { delete node.range; }
      if (node.loc) { delete node.loc; }
      if (node.originalRange) { delete node.originalRange; }
      return node;
    }

    hashString(str) {
      return (__range__(0, str.length, false).map((i) => str.charCodeAt(i))).reduce(((hash, char) => ((hash << 5) + hash) + char), 5381);
    }
  };
  StudentSolutionsView.initClass();
  return StudentSolutionsView;  // hash * 33 + c
})());

function __range__(left, right, inclusive) {
  let range = [];
  let ascending = left < right;
  let end = !inclusive ? right : ascending ? right + 1 : right - 1;
  for (let i = left; ascending ? i < end : i > end; ascending ? i++ : i--) {
    range.push(i);
  }
  return range;
}