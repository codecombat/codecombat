// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let SolutionProblemsView;
require('app/styles/artisans/solution-problems-view.sass');
const RootView = require('views/core/RootView');
const template = require('app/templates/artisans/solution-problems-view');

const Level = require('models/Level');
const Campaign = require('models/Campaign');

const CocoCollection = require('collections/CocoCollection');
const Campaigns = require('collections/Campaigns');
const Levels = require('collections/Levels');

module.exports = (SolutionProblemsView = (function() {
  let excludedCampaigns = undefined;
  let excludedSimulationLevels = undefined;
  let excludedSolutionLevels = undefined;
  let simulationRequirements = undefined;
  let includedLanguages = undefined;
  let excludedLanguages = undefined;
  let excludedLevelSnippets = undefined;
  SolutionProblemsView = class SolutionProblemsView extends RootView {
    static initClass() {
      this.prototype.template = template;
      this.prototype.id = 'solution-problems-view';
      excludedCampaigns = [
        // Misc. campaigns
        'picoctf', 'auditions',
  
        // Campaign-version campaigns
        //'dungeon', 'forest', 'desert', 'mountain', 'glacier'
  
        // Test campaigns
        'dungeon-branching-test', 'forest-branching-test', 'desert-branching-test'
  
        // Course-version campaigns
        //'intro', 'course-2', 'course-3', 'course-4', 'course-5', 'course-6'
      ];
      excludedSimulationLevels = [
        // Course Arenas
        'wakka-maul', 'cross-bones'
      ];
      excludedSolutionLevels = [
        // Multiplayer Levels
        'cavern-survival',
        'dueling-grounds', 'multiplayer-treasure-grove',
        'harrowland',
        'zero-sum',
        'ace-of-coders', 'capture-their-flag'
      ];
      simulationRequirements = [
        'seed',
        'succeeds',
        'heroConfig',
        'frameCount',
        'goals'
      ];
      includedLanguages = [
        'python', 'javascript', 'java', 'lua', 'coffeescript'
      ];
      // TODO: Phase the following out:
      excludedLanguages = [
        'java', 'lua', 'coffeescript'
      ];
      excludedLevelSnippets = [
        'treasure', 'brawl', 'siege'
      ];
  
      this.prototype.unloadedCampaigns = 0;
      this.prototype.campaignLevels = {};
      this.prototype.loadedLevels = {};
      this.prototype.parsedLevels = [];
      this.prototype.problemCount = 0;
    }

    initialize() {
      this.campaigns = new Campaigns([]);
      this.listenTo(this.campaigns, 'sync', this.onCampaignsLoaded);
      return this.supermodel.trackRequest(this.campaigns.fetch({
        data: {
          project:'slug'
        }
      }));
    }

    onCampaignsLoaded(campCollection) {
      return (() => {
        const result = [];
        for (var campaign of Array.from(campCollection.models)) {
          var campaignSlug = campaign.get('slug');
          if (Array.from(excludedCampaigns).includes(campaignSlug)) { continue; }
          this.unloadedCampaigns++;

          this.campaignLevels[campaignSlug] = new Levels();
          this.listenTo(this.campaignLevels[campaignSlug], 'sync', this.onLevelsLoaded);
          result.push(this.supermodel.trackRequest(this.campaignLevels[campaignSlug].fetchForCampaign(campaignSlug, {
            data: {
              project: 'thangs,name,slug,campaign'
            }
          }
          )));
        }
        return result;
      })();
    }

    onLevelsLoaded(lvlCollection) {
      for (var level of Array.from(lvlCollection.models)) {
        this.loadedLevels[level.get('slug')] = level;
      }
      if (--this.unloadedCampaigns === 0) {
        return this.onAllLevelsLoaded();
      }
    }

    onAllLevelsLoaded() {
      for (var levelSlug in this.loadedLevels) {
        var level = this.loadedLevels[levelSlug];
        if (level == null) {
          console.error('Level Slug doesn\'t have associated Level', levelSlug);
          continue;
        }
        if (Array.from(excludedSolutionLevels).includes(levelSlug)) { continue; }
        var isBad = false;
        for (var word of Array.from(excludedLevelSnippets)) {
          if (levelSlug.indexOf(word) !== -1) {
            isBad = true;
          }
        }
        if (isBad) { continue; }
        var thangs = level.get('thangs');
        var component = null;
        thangs = _.filter(thangs, elem => _.findWhere(elem.components, function(elem2) {
          if ((elem2.config != null ? elem2.config.programmableMethods : undefined) != null) {
            component = elem2;
            return true;
          }
        }));

        if (thangs.length > 1) {
          if (!Array.from(excludedSimulationLevels).includes(levelSlug)) {
            console.warn('Level has more than 1 programmableMethod Thangs', levelSlug);
          }
          continue;
        }
        if (component == null) {
          console.error('Level doesn\'t have programmableMethod Thang', levelSlug);
          continue;
        }

        var {
          plan
        } = component.config.programmableMethods;
        var solutions = plan.solutions || [];
        var problems = [];
        problems = problems.concat(this.findMissingSolutions(solutions));
        if (!Array.from(excludedSimulationLevels).includes(levelSlug)) {
          for (var solution of Array.from(solutions)) {
            problems = problems.concat(this.findSimulationProblems(solution));
            problems = problems.concat(this.findPass(solution));
            problems = problems.concat(this.findIdenticalToSource(solution, plan));
            problems = problems.concat(this.findTemplateProblems(solution, plan));
          }
        }
        this.problemCount += problems.length;
        this.parsedLevels.push({
          level,
          problems
        });
      }

      return this.renderSelectors('#level-table');
    }

    findMissingSolutions(solutions) {
      const problems = [];
      for (var lang of Array.from(includedLanguages)) {
        if (_.findWhere(solutions, elem => elem.language === lang)) {
        // TODO: Phase the following out:
        } else if (!Array.from(excludedLanguages).includes(lang)) {
          problems.push({
            type: 'Missing solution language',
            value: lang
          });
        }
      }
      return problems;
    }

    findSimulationProblems(solution) {
      const problems = [];
      for (var req of Array.from(simulationRequirements)) {
        if (solution[req] == null) {
          problems.push({
            type: 'Solution is not simulatable',
            value: solution.language
          });
          break;
        }
      }
      return problems;
    }

    findPass(solution) {
      const problems = [];
      if (solution.source.search(/pass\n/) !== -1) {
        problems.push({
          type: 'Solution contains pass',
          value: solution.language
        });
      }
      return problems;
    }

    findIdenticalToSource(solution, plan) {
      const problems = [];
      const source = solution.lang === 'javascript' ? plan.source : plan.languages[solution.language];
      if (solution.source === source) {
        problems.push({
          type: 'Solution matches sample code',
          value: solution.language
        });
      }
      return problems;
    }

    findTemplateProblems(solution, plan) {
      const problems = [];
      const source = solution.lang === 'javascript' ? plan.source : plan.languages[solution.language];
      const {
        context
      } = plan;
      try {
        _.template(source, context);
      } catch (error) {
        console.log(source, context, error);
        problems.push({
          type: 'Solution template syntax error',
          value: error.message
        });
      }
      return problems;
    }
  };
  SolutionProblemsView.initClass();
  return SolutionProblemsView;
})());
