// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS104: Avoid inline assignments
 * DS204: Change includes calls to have a more natural evaluation order
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let CocoLegacyCampaigns, VerifierView;
require('app/styles/editor/verifier/verifier-view.sass');
const async = require('vendor/scripts/async.js');
const utils = require('core/utils');
const translateUtils = require('lib/translate-utils');

const RootView = require('views/core/RootView');
const template = require('app/templates/editor/verifier/verifier-view');
const VerifierTest = require('./VerifierTest');
const SuperModel = require('models/SuperModel');
const Campaigns = require('collections/Campaigns');
const Level = require('models/Level');

if (utils.isOzaria) {
  CocoLegacyCampaigns = ['intro', 'course-2', 'course-3', 'course-4', 'course-5', 'course-6', 'course-8',
           'dungeon', 'forest', 'desert', 'mountain', 'glacier', 'volcano', 'campaign-game-dev-1',
           'campaign-game-dev-2', 'campaign-game-dev-3', 'hoc-2018'];
} else {
  CocoLegacyCampaigns = [];
}

module.exports = (VerifierView = (function() {
  VerifierView = class VerifierView extends RootView {
    static initClass() {
      this.prototype.className = 'style-flat';
      this.prototype.template = template;
      this.prototype.id = 'verifier-view';

      this.prototype.events =
        {'click #go-button': 'onClickGoButton'};
    }

    constructor(options, levelID) {
      super(options);
      this.update = this.update.bind(this);
      this.levelID = levelID;
      // TODO: sort tests by unexpected result first
      this.passed = 0;
      this.failed = 0;
      this.problem = 0;
      this.testCount = 0;

      if (utils.getQueryVariable('dev')) {
        this.supermodel.shouldSaveBackups = model => // Make sure to load possibly changed things from localStorage.
        ['Level', 'LevelComponent', 'LevelSystem', 'ThangType'].includes(model.constructor.className);
      }

      this.cores = window.navigator.hardwareConcurrency || 4;
      this.careAboutFrames = true;

      if (this.levelID) {
        this.levelIDs = [this.levelID];
        this.testLanguages = ['python', 'javascript', 'java', 'cpp', 'lua', 'coffeescript'];
        this.codeLanguages = (Array.from(this.testLanguages).map((c) => ({id: c, checked: true})));
        this.cores = 1;
        this.startTestingLevels();
      } else {
        this.campaigns = new Campaigns();
        this.supermodel.trackRequest(this.campaigns.fetch({data: {project: 'slug,type,levels'}}));
        this.campaigns.comparator = m => ['intro', 'course-2', 'course-3', 'course-4', 'course-5', 'course-6', 'course-8',
         'dungeon', 'forest', 'desert', 'mountain', 'glacier', 'volcano', 'campaign-game-dev-1', 'campaign-game-dev-2', 'campaign-game-dev-3', 'hoc-2018'].indexOf(m.get('slug'));
      }
    }

    onLoaded() {
      super.onLoaded();
      if (this.levelID) { return; }
      this.filterCampaigns();
      this.filterCodeLanguages();
      return this.render();
    }

    filterCampaigns() {
      this.levelsByCampaign = {};
      return (() => {
        const result = [];
        for (var campaign of Array.from(this.campaigns.models)) {
          var needle, needle1;
          if ((needle = campaign.get('type'), ['course', 'hero', 'hoc'].includes(needle)) && (needle1 = campaign.get('slug'), !Array.from(['picoctf', 'game-dev-1', 'game-dev-2', 'game-dev-3', 'web-dev-1', 'web-dev-2', 'web-dev-3', 'campaign-web-dev-1', 'campaign-web-dev-2', 'campaign-web-dev-3'].concat(CocoLegacyCampaigns)).includes(needle1))) {var name;

            if (this.levelsByCampaign[name = campaign.get('slug')] == null) { var needle2;
            this.levelsByCampaign[name] = {levels: [], checked: (needle2 = campaign.get('slug'), ['intro'].includes(needle2))}; }
            var campaignInfo = this.levelsByCampaign[campaign.get('slug')];
            result.push((() => {
              const result1 = [];
              const object = campaign.get('levels');
              for (var levelID in object) {  // Would use isType, but it's not a Level model
                var level = object[levelID];
                if (!['hero-ladder', 'course-ladder', 'web-dev', 'ladder'].includes(level.type)) {
                  result1.push(campaignInfo.levels.push(level.slug));
                }
              }
              return result1;
            })());
          }
        }
        return result;
      })();
    }

    filterCodeLanguages() {
      const defaultLanguages = utils.getQueryVariable('languages', 'python,javascript').split(/, ?/);
      return this.codeLanguages != null ? this.codeLanguages : (this.codeLanguages = (['python', 'javascript', 'java', 'cpp', 'lua', 'coffeescript'].map((c) => ({id: c, checked: Array.from(defaultLanguages).includes(c)}))));
    }

    onClickGoButton(e) {
      this.filterCampaigns();
      this.levelIDs = [];
      this.careAboutFrames = this.$("#careAboutFrames").is(':checked');
      this.cores = this.$("#cores").val()|0;
      for (var campaign in this.levelsByCampaign) {
        var campaignInfo = this.levelsByCampaign[campaign];
        if (this.$(`#campaign-${campaign}-checkbox`).is(':checked')) {
          for (var level of Array.from(campaignInfo.levels)) {
            if (!Array.from(this.levelIDs).includes(level)) { this.levelIDs.push(level); }
          }
        } else {
          campaignInfo.checked = false;
        }
      }
      this.testLanguages = [];
      for (var codeLanguage of Array.from(this.codeLanguages)) {
        if (this.$(`#code-language-${codeLanguage.id}-checkbox`).is(':checked')) {
          codeLanguage.checked = true;
          this.testLanguages.push(codeLanguage.id);
        } else {
          codeLanguage.checked = false;
        }
      }
      return this.startTestingLevels();
    }

    startTestingLevels() {
      this.levelsToLoad = (this.initialLevelsToLoad = this.levelIDs.length);
      return (() => {
        const result = [];
        for (var levelID of Array.from(this.levelIDs)) {
          var level = this.supermodel.getModel(Level, levelID) || new Level({_id: levelID});
          if (level.loaded) {
            result.push(this.onLevelLoaded());
          } else {
            result.push(this.listenToOnce(this.supermodel.loadModel(level).model, 'sync', this.onLevelLoaded));
          }
        }
        return result;
      })();
    }

    onLevelLoaded() {
      if (--this.levelsToLoad === 0) {
        return this.onTestLevelsLoaded();
      } else {
        return this.render();
      }
    }

    onTestLevelsLoaded() {

      let level, solution;
      this.linksQueryString = window.location.search;
      //supermodel = if @levelID then @supermodel else undefined
      this.tests = [];
      this.testsByLevelAndLanguage = {};
      this.tasksList = [];
      for (var levelID of Array.from(this.levelIDs)) {
        level = this.supermodel.getModel(Level, levelID);
        for (var codeLanguage of Array.from(this.testLanguages)) {
          var left;
          var solutions = _.filter((left = (level != null ? level.getSolutions() : undefined)) != null ? left : [], {language: codeLanguage});
          // If there are no target language solutions yet, generate them from JavaScript.
          if (['cpp', 'java', 'python', 'lua', 'coffeescript'].includes(codeLanguage) && (solutions.length === 0)) {
            var left1;
            var transpiledSolutions = _.filter((left1 = (level != null ? level.getSolutions() : undefined)) != null ? left1 : [], {language: 'javascript'});
            for (var s of Array.from(transpiledSolutions)) {
              s.language = codeLanguage;
              s.source = translateUtils.translateJS(s.source, codeLanguage);
              s.transpiled = true;
            }
            solutions = transpiledSolutions;
          }
          if (solutions.length) {
            for (solution of Array.from(solutions)) {
              this.tasksList.push({level: levelID, language: codeLanguage, solution});
            }
          } else {
            this.tasksList.push({level: levelID, language: codeLanguage});
          }
        }
      }

      this.tasksToRerun = [];
      this.testCount = this.tasksList.length;
      console.log("Starting in", this.cores, "cores...");
      const chunks = _.groupBy(this.tasksList, (v,i) => i%this.cores);
      const supermodels = [this.supermodel];

      return _.forEach(chunks, (chunk, i) => {
        return _.delay(() => {
          const parentSuperModel = supermodels[supermodels.length-1];
          const chunkSupermodel = new SuperModel();
          chunkSupermodel.models = _.clone(parentSuperModel.models);
          chunkSupermodel.collections = _.clone(parentSuperModel.collections);
          supermodels.push(chunkSupermodel);
          this.render();
          return async.eachSeries(chunk, (task, next) => {
            var test = new VerifierTest(task.level, e => {
              this.update(e);
              if (['complete', 'error', 'no-solution'].includes(e.state)) {
                if (e.state === 'complete') {
                  if (test.isSuccessful(this.careAboutFrames)) {
                    ++this.passed;
                  } else if (this.cores > 1) {
                    ++this.failed;
                    this.tasksToRerun.push(task);
                  } else {
                    ++this.failed;
                  }
                } else if (e.state === 'no-solution') {
                  --this.testCount;
                } else {
                  ++this.problem;
                }
                return next();
              }
            }
            , chunkSupermodel, task.language, { solution: task.solution });
            this.tests.push(test);
            if (this.testsByLevelAndLanguage[task.level] == null) { this.testsByLevelAndLanguage[task.level] = {}; }
            if (this.testsByLevelAndLanguage[task.level][task.language] == null) { this.testsByLevelAndLanguage[task.level][task.language] = []; }
            this.testsByLevelAndLanguage[task.level][task.language].push(test);
            this.renderSelectors(`.tasks-group[data-task-slug='${task.level}'][data-task-language='${task.language}']`);
            this.renderSelectors('.verifier-row');
            return this.renderSelectors('.progress');
          }
          , () => {
            if (!this.testsRemaining()) {
              this.render();
              return this.rerunFailedTests();
            }
          });
        }
        , i > 0 ? 5000 + (i * 1000) : 0);
      });
    }

    rerunFailedTests() {
      let test;
      if (!this.tasksToRerun.length || (this.cores === 1)) {
        console.log(((() => {
          const result = [];
          for (test of Array.from(this.tests)) {             if (!test.isSuccessful()) {
              result.push([test.level.get('slug'), test.language].join('\t'));
            }
          }
          return result;
        })()).join('\n'));
        return;
      }

      for (test of Array.from(this.tests.slice())) {
        // Remove these tests, we'll redo them
        if ((test.state === 'complete') && !test.isSuccessful(this.careAboutFrames)) {
          this.tests = _.without(this.tests, test);
          this.testsByLevelAndLanguage[test.level.get('slug')][test.language] = _.without(this.testsByLevelAndLanguage[test.level.get('slug')][test.language], test);
        }
      }

      const {
        tasksToRerun
      } = this;
      this.tasksToRerun = [];
      const testSupermodel = new SuperModel();
      testSupermodel.models = _.clone(this.supermodel.models);
      testSupermodel.collections = _.clone(this.supermodel.collections);
      return async.eachSeries(tasksToRerun, (task, next) => {
        test = new VerifierTest(task.level, e => {
          this.update(e);
          if (['complete', 'error', 'no-solution'].includes(e.state)) {
            if (e.state === 'complete') {
              if (test.isSuccessful(this.careAboutFrames)) {
                --this.failed;
                ++this.passed;
              }
            } else {
              --this.failed;
              ++this.problem;
            }
            return next();
          }
        }
        , testSupermodel, task.language, { solution: task.solution });
        this.tests.push(test);
        this.testsByLevelAndLanguage[task.level][task.language].push(test);
        this.renderSelectors(`.tasks-group[data-task-slug='${task.level}'][data-task-language='${task.language}']`);
        this.renderSelectors('.verifier-row');
        return this.renderSelectors('.progress');
      }
      , () => {
        this.render();
        return console.log(((() => {
          const result1 = [];
          for (test of Array.from(this.tests)) {             if (!test.isSuccessful()) {
              result1.push([test.level.get('slug'), test.language].join('\t'));
            }
          }
          return result1;
        })()).join('\n'));
      });
    }

    testsRemaining() { return this.testCount - this.passed - this.problem - this.failed; }

    update(event) {
      if (event && (event.test.level != null ? event.test.level.get('slug') : undefined)) {
        this.renderSelectors(`.tasks-group[data-task-slug='${event.test.level.get('slug')}'][data-task-language='${event.test.language}']`);
        this.renderSelectors('.verifier-row');
        return this.renderSelectors('.progress');
      } else {
        return this.render();
      }
    }
  };
  VerifierView.initClass();
  return VerifierView;
})());
