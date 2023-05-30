// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let LevelConceptMap, parser, realm;
require('app/styles/artisans/solution-problems-view.sass');
const RootView = require('views/core/RootView');
const template = require('app/templates/artisans/concept-map-view');

const Level = require('models/Level');
const Campaign = require('models/Campaign');

const CocoCollection = require('collections/CocoCollection');
const Campaigns = require('collections/Campaigns');
const Levels = require('collections/Levels');
const tagger = require('lib/SolutionConceptTagger');
const conceptList = require('schemas/concepts');
const loadAetherLanguage = require('lib/loadAetherLanguage');
const utils = require('core/utils');

if (utils.isOzaria) {
  if (typeof esper !== 'undefined') {
    ({
      realm
    } = new esper());
    parser = realm.parser.bind(realm);
  }
}

module.exports = (LevelConceptMap = (function() {
  let excludedCampaigns = undefined;
  let includedLanguages = undefined;
  let excludedLevelSnippets = undefined;
  LevelConceptMap = class LevelConceptMap extends RootView {
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
  
      includedLanguages = [
        'javascript'
      ];
  
      excludedLevelSnippets = [
        'treasure', 'brawl', 'siege'
      ];
  
      this.prototype.unloadedCampaigns = 0;
      this.prototype.campaignLevels = {};
      this.prototype.loadedLevels = {};
      this.prototype.data = {};
      this.prototype.problemCount = 0;
    }

    initialize() {
      if (utils.isCodeCombat) {
        loadAetherLanguage('javascript').then(aetherLang => {
          if (typeof esper !== 'undefined') {
            ({
              realm
            } = new esper());
            return this.parser = realm.parser.bind(realm);
          }
        });
      }
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
          this.listenTo(this.campaignLevels[campaignSlug], 'sync', this.onLevelsLoaded.bind(this, campaignSlug));
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

    onLevelsLoaded(campaignSlug, lvlCollection) {
      for (let k = 0; k < lvlCollection.models.length; k++) {
        var level = lvlCollection.models[k];
        level.campaign = campaignSlug;
        if (this.loadedLevels[campaignSlug] == null) { this.loadedLevels[campaignSlug] = {}; }
        if (ll == null) { var ll = {}; }
        level.seqNo = lvlCollection.models.length - k;
        this.loadedLevels[campaignSlug][level.get('slug')] = level;
      }
      if (--this.unloadedCampaigns === 0) {
        return this.onAllLevelsLoaded();
      }
    }

    onAllLevelsLoaded() {
      for (var campaignSlug in this.loadedLevels) {
        var campaign = this.loadedLevels[campaignSlug];
        for (var levelSlug in campaign) {
          var level = campaign[levelSlug];
          if (level == null) {
            console.error('Level Slug doesn\'t have associated Level', levelSlug);
            continue;
          }

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

          if (utils.isCodeCombat && (thangs.length > 2)) {
            console.warn('Level has more than 2 programmableMethod Thangs', levelSlug);
            continue;
          }

          if (utils.isOzaria && (thangs.length > 1)) {
            console.warn('Level has more than 1 programmableMethod Thangs', levelSlug);
            continue;
          }

          if (component == null) {
            console.error('Level doesn\'t have programmableMethod Thang', levelSlug);
            continue;
          }

          var {
            plan
          } = component.config.programmableMethods;
          level.tags = this.tagLevel(_.find(plan.solutions, s => s.language === 'javascript'));
        }
        this.data[campaignSlug] = _.sortBy(_.values(this.loadedLevels[campaignSlug]), 'seqNo');
      }

      if (utils.isOzaria) {
        console.log(this.render, this.loadedLevels);
      }
      return this.render();
    }

    tagLevel(src) {
      let ast, moreTags;
      if (((src != null ? src.source : undefined) == null)) { return []; }
      try {
        ast = this.parser(src.source);
        moreTags = tagger(src);
      } catch (error) {
        const e = error;
        return ['parse error: ' + e.message];
      }

      const tags = {};
      var process = function(n) {
        if (n == null) { return; }
        switch (n.type) {
          case "Program": case "BlockStatement":
            return (() => {
              const result = [];
              for (n of Array.from(n.body)) {                 result.push(process(n));
              }
              return result;
            })();
          case "FunctionDeclaration":
            tags['function-def'] = true;
            if (n.params > 0) {
              tags['function-params:' + n.params.length] = true;
            }
            return process(n.body);
          case "ExpressionStatement":
            return process(n.expression);
          case "CallExpression":
            return process(n.callee);
          case "MemberExpression":
            if ((n.object != null ? n.object.name : undefined) === 'hero') {
              return tags["hero." + n.property.name] = true;
            }
            break;
          case "WhileStatement":
            if ((n.test.type === 'Literal') && (n.test.value === true)) {
              tags['while-true'] = true;
            } else {
              tags['while'] = true;
              process(n.test);
            }
            return process(n.body);
          case "ForStatement":
            tags['for'] = true;
            process(n.init);
            process(n.test);
            process(n.update);
            return process(n.body);
          case "IfStatement":
            tags['if'] = true;
            process(n.test);
            process(n.consequent);
            return process(n.alternate);
          case "Literal":
            if (n.value === true) {
              return tags['true'] = true;
            } else {
              return tags['literal:' + typeof n.value] = true;
            }
          case "BinaryExpression":case "LogicalExpression":
            process(n.left);
            process(n.right);
            return tags[n.operator] = true;
          case "AssignmentExpression":
            tags['assign:' + n.operator] = true;
            return process(n.right);
          default:
            return tags[n.type] = true;
        }
      };



      process(ast);


      Object.keys(tags).concat(moreTags);
      return _.map(moreTags, t => __guard__(_.find(conceptList, e => e.concept === t), x => x.name));
    }
  };
  LevelConceptMap.initClass();
  return LevelConceptMap;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}