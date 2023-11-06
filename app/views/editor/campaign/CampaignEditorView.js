// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let CampaignEditorView;
require('app/styles/editor/campaign/campaign-editor-view.sass');
const RootView = require('views/core/RootView');
const Campaign = require('models/Campaign');
const Level = require('models/Level');
const Achievement = require('models/Achievement');
const ThangType = require('models/ThangType');
const CampaignView = require('views/play/CampaignView');
const CocoCollection = require('collections/CocoCollection');
require('lib/setupTreema');
const treemaExt = require('core/treema-ext');
const utils = require('core/utils');
const RelatedAchievementsCollection = require('collections/RelatedAchievementsCollection');
const CampaignAnalyticsModal = require('./CampaignAnalyticsModal');
const CampaignLevelView = require('./CampaignLevelView');
const SaveCampaignModal = require('./SaveCampaignModal');
const PatchesView = require('views/editor/PatchesView');
const RevertModal = require('views/modal/RevertModal');
const modelDeltas = require('lib/modelDeltas');
const globalVar = require('core/globalVar');
require('vendor/scripts/jquery-ui-1.11.1.custom');
require('vendor/styles/jquery-ui-1.11.1.custom.css');

require('lib/game-libraries');

const achievementProject = ['related', 'rewards', 'name', 'slug'];
const thangTypeProject = ['name', 'original'];

module.exports = (CampaignEditorView = (function() {
  CampaignEditorView = class CampaignEditorView extends RootView {
    static initClass() {
      this.prototype.id = "campaign-editor-view";
      this.prototype.template = require('app/templates/editor/campaign/campaign-editor-view');
      this.prototype.className = 'editor';

      this.prototype.events = {
        'click #analytics-button': 'onClickAnalyticsButton',
        'click #save-button': 'onClickSaveButton',
        'click #patches-button': 'onClickPatches',
        'click [data-toggle="coco-modal"][data-target="modal/RevertModal"]': 'openRevertModal'
      };

      this.prototype.subscriptions =
        {'editor:campaign-analytics-modal-closed' : 'onAnalyticsModalClosed'};
    }

    constructor(options, campaignHandle, campaignPage) {
      super(options);
      this.onTreemaChanged = this.onTreemaChanged.bind(this);
      this.onTreemaSelectionChanged = this.onTreemaSelectionChanged.bind(this);
      this.onTreemaDoubleClicked = this.onTreemaDoubleClicked.bind(this);
      this.onAchievementUpdated = this.onAchievementUpdated.bind(this);
      this.campaignHandle = campaignHandle;
      this.campaignPage = campaignPage;
      this.campaignPage = parseInt(this.campaignPage) || 1;
      this.campaign = new Campaign({_id:this.campaignHandle});
      this.supermodel.loadModel(this.campaign);
      this.listenToOnce(this.campaign, 'sync', function(model, response, jqXHR) {
        this.campaign.set('_id', response._id);
        return this.campaign.url = function() { return '/db/campaign/' + this.id; };
      });

      // Save reference to data used by anlytics modal so it persists across modal open/closes.
      this.campaignAnalytics = {};

      this.levels = new CocoCollection([], {
        model: Level,
        url: `/db/campaign/${this.campaignHandle}/levels`,
        project: Campaign.denormalizedLevelProperties
      });
      this.supermodel.loadCollection(this.levels, 'levels');

      this.achievements = new CocoCollection([], {
        model: Achievement,
        url: `/db/campaign/${this.campaignHandle}/achievements`,
        project: achievementProject
      });
      this.supermodel.loadCollection(this.achievements, 'achievements');

      this.toSave = new Backbone.Collection();
      this.listenToOnce(this.campaign ,'sync', this.loadThangTypeNames);
      this.listenToOnce(this.campaign, 'sync', this.onFundamentalLoaded);
      this.listenToOnce(this.levels, 'sync', this.onFundamentalLoaded);
      this.listenToOnce(this.achievements, 'sync', this.onFundamentalLoaded);
    }

    openRevertModal(e) {
      e.stopPropagation();
      return this.openModalView(new RevertModal());
    }

    onLeaveMessage() {
      for (var model of Array.from(this.toSave.models)) {
        var diff = modelDeltas.getDelta(model);
        if (_.size(diff)) {
          console.log('model, diff', model, diff);
          return 'You have changes!';
        }
      }
    }

    loadThangTypeNames() {
      // Load the names of the ThangTypes that this level's Treema nodes might want to display.
      let originals = [];
      for (var level of Array.from(_.values(this.campaign.get('levels')))) {
        if (level.requiredGear) { originals = originals.concat(_.values(level.requiredGear)); }
        if (level.restrictedGear) { originals = originals.concat(_.values(level.restrictedGear)); }
      }
      originals = _.uniq(_.flatten(originals));
      return (() => {
        const result = [];
        for (var original of Array.from(originals)) {
          var thangType = new ThangType();
          thangType.setProjection(thangTypeProject);
          thangType.setURL(`/db/thang.type/${original}/version`);
          result.push(this.supermodel.loadModel(thangType));
        }
        return result;
      })();
    }

    onFundamentalLoaded() {
      // Load any levels which haven't been denormalized into our campaign.
      if (!this.campaign.loaded || !this.levels.loaded || !this.achievements.loaded) { return; }
      return this.loadMissingLevelsAndRelatedModels();
    }

    loadMissingLevelsAndRelatedModels() {
      const promises = [];
      for (var level of Array.from(_.values(this.campaign.get('levels')))) {
        var model;
        if (model = this.levels.findWhere({original: level.original})) { continue; }
        model = new Level({});
        model.setProjection(Campaign.denormalizedLevelProperties);
        model.setURL(`/db/level/${level.original}/version`);
        var levelResource = this.supermodel.loadModel(model);
        this.levels.add(levelResource.model);
        // Handle SuperModel's caching, and make sure loaded levels save and notice changes properly
        if (levelResource.jqxhr) {
          levelResource.model.once('sync', function() {
            this.setURL(`/db/level/${this.id}`);
            return this.markToRevert();
          });
          promises.push(levelResource.jqxhr);
        }
        var achievements = new RelatedAchievementsCollection(level.original);
        achievements.setProjection(achievementProject);
        var achievementsResource = this.supermodel.loadCollection(achievements);
        promises.push(achievementsResource.jqxhr);
        this.listenToOnce(achievements, 'sync', function(achievementsLoaded) {
          return this.achievements.add(achievementsLoaded.models);
        });
      }
      return Promise.resolve($.when(...Array.from(promises || [])));
    }

    onLoaded() {
      this.updateCampaignLevels();
      this.campaignView.render();
      super.onLoaded();
      if (window.location.hash) {
        const levelSlug = window.location.hash.substring(1);
        const levelOriginal = _.find(this.campaign.get('levels'), {slug: levelSlug}).original;
        return this.openCampaignLevelView(this.supermodel.getModelByOriginal(Level, levelOriginal));
      }
    }

    updateCampaignLevels() {
      let level, model;
      if (this.campaign.hasLocalChanges()) { this.toSave.add(this.campaign); }
      const campaignLevels = $.extend({}, this.campaign.get('levels'));
      for (let levelIndex = 0; levelIndex < this.levels.models.length; levelIndex++) {
        level = this.levels.models[levelIndex];
        var levelOriginal = level.get('original');
        var campaignLevel = campaignLevels[levelOriginal];
        if (!campaignLevel) { continue; }
        $.extend(campaignLevel, _.pick(level.attributes, Campaign.denormalizedLevelProperties));
        // TODO: better way for it to remember when we intend to not specifically require/restrict gear any more
        if (!level.attributes.requiredGear) { delete campaignLevel.requiredGear; }
        if (!level.attributes.restrictedGear) { delete campaignLevel.restrictedGear; }
        campaignLevel.rewards = this.formatRewards(level);
        // Coco: Save campaign to level if it's a main 'hero' campaign so HeroVictoryModal knows where to return.
        // Ozar: Save campaign to level if its of type 'course' so 'Back to unit map' knows where to return.
        // (Not if it's a defaulted, typeless campaign like game-dev-hoc or auditions.)
        var ctype = utils.isCodeCombat ? 'hero' : 'course';
        if (this.campaign.get('type') === ctype) { campaignLevel.campaign = this.campaign.get('slug'); }
        campaignLevels[levelOriginal] = campaignLevel;
      }

      this.campaign.set('levels', campaignLevels);

      for (level of Array.from(_.values(campaignLevels))) {
        if (/test/.test(this.campaign.get('slug'))) { continue; }  // Don't overwrite level stuff for testing Campaigns
        if (utils.isCodeCombat) {
          model = this.levels.findWhere({original: level.original});
        } else {
          model = this.supermodel.getModelByOriginal(Level, level.original);
        }
        // do not propagate campaignIndex for non-course campaigns
        var propsToPropagate = Campaign.denormalizedLevelProperties;
        if (this.campaign.get('type') !== 'course') {
          propsToPropagate = _.without(propsToPropagate, 'campaignIndex');
        }
        for (var key of Array.from(propsToPropagate)) {
          if (model.get(key) !== level[key]) { model.set(key, level[key]); }
        }
        if (model.hasLocalChanges()) { this.toSave.add(model); }
      }

      // Update name/slug/type properties in the `nextLevels` property of campaign levels
      if (utils.isOzaria) {
        return (() => {
          const result = [];
          for (level of Array.from(_.values(campaignLevels))) {
            result.push((() => {
              const result1 = [];
              for (var nextLevel of Array.from(_.values(level.nextLevels))) {
                model = this.levels.findWhere({original: nextLevel.original});
                if (model) {
                  result1.push($.extend(nextLevel, _.pick(model.attributes, Campaign.nextLevelProperties)));
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
    }

    formatRewards(level) {
      const achievements = this.achievements.where({related: level.get('original')});
      const rewards = [];
      for (var achievement of Array.from(achievements)) {
        var object = achievement.get('rewards');
        for (var rewardType in object) {
          var rewardArray = object[rewardType];
          for (var reward of Array.from(rewardArray)) {
            var thangType;
            var rewardObject = { achievement: achievement.id };

            if (rewardType === 'heroes') {
              rewardObject.hero = reward;
              thangType = new ThangType({}, {project: thangTypeProject});
              thangType.setURL(`/db/thang.type/${reward}/version`);
              this.supermodel.loadModel(thangType);
            }

            if (rewardType === 'levels') {
              rewardObject.level = reward;
              if (!this.levels.findWhere({original: reward})) {
                level = new Level({}, {project: Campaign.denormalizedLevelProperties});
                level.setURL(`/db/level/${reward}/version`);
                this.supermodel.loadModel(level);
              }
            }

            if (rewardType === 'items') {
              rewardObject.item = reward;
              thangType = new ThangType({}, {project: thangTypeProject});
              thangType.setURL(`/db/thang.type/${reward}/version`);
              this.supermodel.loadModel(thangType);
            }

            rewards.push(rewardObject);
          }
        }
      }
      return rewards;
    }

    propagateCampaignIndexes() {
      const campaignLevels = $.extend({}, this.campaign.get('levels'));
      let index = 0;
      return (() => {
        const result = [];
        for (var levelOriginal in campaignLevels) {
          var campaignLevel = campaignLevels[levelOriginal];
          if (this.campaign.get('type') === 'course') {
            var level = this.levels.findWhere({original: levelOriginal});
            if (level && (level.get('campaignIndex') !== index)) {
              level.set('campaignIndex', index);
            }
          }
          campaignLevel.campaignIndex = index;
          index += 1;
          result.push(this.campaign.set('levels', campaignLevels));
        }
        return result;
      })();
    }

    onClickPatches(e) {
      this.patchesView = this.insertSubView(new PatchesView(this.campaign), this.$el.find('.patches-view'));
      this.patchesView.load();
      return this.patchesView.$el.removeClass('hidden');
    }

    onClickAnalyticsButton() {
      return this.openModalView(new CampaignAnalyticsModal({}, this.campaignHandle, this.campaignAnalytics));
    }

    onAnalyticsModalClosed(options) {
      if ((options.targetLevelSlug != null) && (__guard__(this.treema.childrenTreemas != null ? this.treema.childrenTreemas.levels : undefined, x => x.childrenTreemas) != null)) {
        return (() => {
          const result = [];
          for (var original in this.treema.childrenTreemas.levels.childrenTreemas) {
            var level = this.treema.childrenTreemas.levels.childrenTreemas[original];
            if ((level.data != null ? level.data.slug : undefined) === options.targetLevelSlug) {
              this.openCampaignLevelView(this.supermodel.getModelByOriginal(Level, original));
              break;
            } else {
              result.push(undefined);
            }
          }
          return result;
        })();
      }
    }

    onClickSaveButton(e) {
      if (this.openingModal) { return; }
      this.openingModal = true;
      return this.loadMissingLevelsAndRelatedModels().then(() => {
        this.openingModal = false;
        this.propagateCampaignIndexes();
        this.updateCampaignLevels();
        this.toSave.set(this.toSave.filter(m => m.hasLocalChanges()));
        return this.openModalView(new SaveCampaignModal({}, this.toSave));
      });
    }

    afterRender() {
      super.afterRender();
      const treemaOptions = {
        schema: Campaign.schema,
        data: $.extend({}, this.campaign.attributes),
        filePath: `db/campaign/${this.campaign.get('_id')}`,
        callbacks: {
          change: this.onTreemaChanged,
          select: this.onTreemaSelectionChanged,
          dblclick: this.onTreemaDoubleClicked,
          achievementUpdated: this.onAchievementUpdated
        },
        nodeClasses: {
          levels: utils.isCodeCombat ? CocoLevelsNode : OzarLevelsNode,
          level: LevelNode,
          nextLevel: NextLevelNode,
          campaigns: utils.isCodeCombat ? CocoCampaignsNode : OzarCampaignsNode,
          campaign: CampaignNode,
          achievement: AchievementNode,
          rewards: RewardsNode
        },
        supermodel: this.supermodel
      };

      this.treema = this.$el.find('#campaign-treema').treema(treemaOptions);
      this.treema.build();
      this.treema.open();
      if (this.treema.childrenTreemas.levels != null) {
        this.treema.childrenTreemas.levels.open();
      }

      this.campaignView = new CampaignView({editorMode: true, supermodel: this.supermodel, campaignPage: this.campaignPage}, this.campaignHandle);
      this.campaignView.highlightElement = _.noop; // make it stop
      this.listenTo(this.campaignView, 'level-moved', this.onCampaignLevelMoved);
      this.listenTo(this.campaignView, 'adjacent-campaign-moved', this.onAdjacentCampaignMoved);
      this.listenTo(this.campaignView, 'level-clicked', this.onCampaignLevelClicked);
      this.listenTo(this.campaignView, 'level-double-clicked', this.onCampaignLevelDoubleClicked);
      this.listenTo(this.campaign, 'change:i18n', () => {
        this.campaign.updateI18NCoverage();
        this.treema.set('/i18n', this.campaign.get('i18n'));
        return this.treema.set('/i18nCoverage', this.campaign.get('i18nCoverage'));
      });

      return this.insertSubView(this.campaignView);
    }

    onTreemaChanged(e, nodes) {
      let key;
      if (!/test/.test(this.campaign.get('slug'))) {  // Don't overwrite level stuff for testing Campaigns
        for (var node of Array.from(nodes)) {
          var path = node.getPath();
          if (_.string.startsWith(path, '/levels/')) {
            var parts = path.split('/');
            var original = parts[2];
            var level = this.supermodel.getModelByOriginal(Level, original);
            var campaignLevel = this.treema.get(`/levels/${original}`);
            for (key of Array.from(Campaign.denormalizedLevelProperties)) { level.set(key, campaignLevel[key]); }
            if (level.hasLocalChanges()) { this.toSave.add(level); }
          }
        }
      }

      this.toSave.add(this.campaign);
      for (key in this.treema.data) { var value = this.treema.data[key]; this.campaign.set(key, value); }
      return this.campaignView.setCampaign(this.campaign);
    }

    onTreemaSelectionChanged(e, node) {
      if (__guard__(node[0] != null ? node[0].data : undefined, x => x.original) == null) { return; }
      const elem = this.$(`div[data-level-original='${node[0].data.original}']`);
      elem.toggle('pulsate');
      return setTimeout(() => elem.toggle('pulsate')
      , 1000);
    }

    onTreemaDoubleClicked(e, node) {
      const path = node.getPath();
      if (!_.string.startsWith(path, '/levels/')) { return; }
      const original = path.split('/')[2];
      return this.openCampaignLevelView(this.supermodel.getModelByOriginal(Level, original));
    }

    onAchievementUpdated(e, node) {
      this.supermodel.registerModel(e.achievement);
      this.achievements.findWhere({_id: e.achievement.id}).set('rewards', e.achievement.get('rewards'));
      this.updateCampaignLevels();  // TODO: only change the rewards for the one we had, don't wipe anything else
      const levelOriginal = node.getPath().split('/')[2];
      const level = this.levels.findWhere({original: levelOriginal});
      const rewardsPath = `/levels/${levelOriginal}/rewards`;
      this.treema.set(rewardsPath, this.formatRewards(level));
      return this.campaignView.setCampaign(this.campaign);
    }

    onCampaignLevelMoved(e) {
      const path = `levels/${e.levelOriginal}/position`;
      return this.treema.set(path, e.position);
    }

    onAdjacentCampaignMoved(e) {
      const path = `adjacentCampaigns/${e.campaignID}/position`;
      return this.treema.set(path, e.position);
    }

    onCampaignLevelClicked(levelOriginal) {
      let levelTreema;
      if (!(levelTreema = __guard__(__guard__(this.treema.childrenTreemas != null ? this.treema.childrenTreemas.levels : undefined, x1 => x1.childrenTreemas), x => x[levelOriginal]))) { return; }
      if (key.ctrl || key.command) {
        const url = `/editor/level/${levelTreema.data.slug}`;
        window.open(url, '_blank');
      }
      return levelTreema.select();
    }
      //levelTreema.open()

    onCampaignLevelDoubleClicked(levelOriginal) {
      return this.openCampaignLevelView(this.supermodel.getModelByOriginal(Level, levelOriginal));
    }

    openCampaignLevelView(level) {
      let campaignLevelView;
      this.insertSubView(campaignLevelView = new CampaignLevelView({}, level));
      this.listenToOnce(campaignLevelView, 'hidden', () => this.$el.find('#campaign-view').show());
      return this.$el.find('#campaign-view').hide();
    }

    onClickLoginButton() {}
      // Do Nothing
      // This is a override method to RootView, so that only CampaignView is listenting to login button click

    onClickSignupButton() {}
  };
  CampaignEditorView.initClass();
  return CampaignEditorView;
})());
    // Do Nothing
    // This is a override method to RootView, so that only CampaignView is listenting to signup button click

// todo: can we use ozar levels node for coco too?
class CocoLevelsNode extends TreemaObjectNode {
  constructor(...args) {
    this.childSource = this.childSource.bind(this);
    super(...args);
  }

  static initClass() {
    this.prototype.valueClass = 'treema-levels';
    this.levels = {};
    this.prototype.ordered = true;
  }

  buildValueForDisplay(valEl, data) {
    return this.buildValueForDisplaySimply(valEl, ''+_.size(data));
  }

  childPropertiesAvailable() { return this.childSource; }

  childSource(req, res) {
    const s = new Backbone.Collection([], {model:Level});
    s.url = '/db/level';
    s.fetch({data: {term:req.term, project: Campaign.denormalizedLevelProperties.join(',')}});
    return s.once('sync', collection => {
      for (var level of Array.from(collection.models)) {
        LevelsNode.levels[level.get('original')] = level;
        this.settings.supermodel.registerModel(level);
      }
      const mapped = (Array.from(collection.models).map((r) => ({label: r.get('name'), value: r.get('original')})));

      // Sort the results. Prioritize names that start with the search term, then contain the search term.
      const lowerPriority = _.clone(mapped);
      const lowerTerm = req.term.toLowerCase();
      const startsWithTerm = _.filter(lowerPriority, item => _.string.startsWith(item.label.toLowerCase(), lowerTerm));
      _.pull(lowerPriority, ...Array.from(startsWithTerm));
      const hasTerm = _.filter(lowerPriority, item => _.string.contains(item.label.toLowerCase(), lowerTerm));
      _.pull(lowerPriority, ...Array.from(hasTerm));
      const sorted = _.flatten([startsWithTerm, hasTerm, lowerPriority]);
      return res(sorted);
    });
  }
}
CocoLevelsNode.initClass();

class OzarLevelsNode extends TreemaObjectNode {
  static initClass() {
    this.prototype.valueClass = 'treema-levels';
    this.levels = {};
    this.mapped = [];
    this.prototype.ordered = true;
  }

  constructor(...args) {
    this.childSource = this.childSource.bind(this);
    super(...Array.from(args || []));
    const s = new Backbone.Collection([], {model:Level});
    s.url = '/db/level';
    s.url += '?archived=false';
    s.fetch({data: {project: Campaign.denormalizedLevelProperties.join(',')}});
    s.once('sync', collection => {
      for (var level of Array.from(collection.models)) {
        LevelsNode.levels[level.get('original')] = level;
        this.settings.supermodel.registerModel(level);
      }
      return this.mapped = (Array.from(collection.models).map((r) => ({label: r.get('name'), value: r.get('original')})));
    });
  }

  buildValueForDisplay(valEl, data) {
    return this.buildValueForDisplaySimply(valEl, ''+_.size(data));
  }

  childPropertiesAvailable() { return this.childSource; }

  childSource(req, res) {
    // Sort the results. Prioritize names that start with the search term, then contain the search term.
    const lowerTerm = req.term.toLowerCase();
    const sorted = _.filter(this.mapped, item => _.string.contains(item.label.toLowerCase(), lowerTerm));
    const startsWithTerm = _.filter(sorted, item => _.string.startsWith(item.label.toLowerCase(), lowerTerm));
    _.pull(sorted, ...Array.from(startsWithTerm));
    return res(_.flatten([startsWithTerm, sorted]));
  }
}
OzarLevelsNode.initClass();

var LevelsNode = utils.isCodeCombat ? CocoLevelsNode : OzarLevelsNode;

class LevelNode extends TreemaObjectNode {
  static initClass() {
    this.prototype.valueClass = 'treema-level';
  }
  buildValueForDisplay(valEl, data) {
    let {
      name
    } = data;
    if (data.requiresSubscription) {
      name = "[P] " + name;
    }
    if (data.displayName) {
      name = name + " - " + data.displayName;
    }

    let status = '';
    let el = 'strong';
    if (data.adminOnly) {
      status += " (disabled)";
      el = 'span';
    } else if (data.adventurer) {
      status += " (adventurer)";
    } else if (utils.isCodeCombat && (data.releasePhase === 'beta')) {
      status += " (beta)";
      el = 'span';
    }

    const completion = '';

    const published = data.permissions != null ? data.permissions.some(permission => (permission.access === 'read') && (permission.target === 'public')) : undefined;

    valEl.append($(`<a href='/editor/level/${_.string.slugify(data.name)}' class='spr'>(e)</a>`));

    if (!published) {
      valEl.append($('<a class="unpublished" title="Unpublished!">&#9888;</a>'));
    }

    valEl.append($(`<${el}></${el}>`).addClass('treema-shortened').text(name));

    if (status) {
      valEl.append($('<em class="spl"></em>').text(status));
    }
    if (completion) {
      return valEl.append($('<span class="completion"></span>').text(completion));
    }
  }

  populateData() {
    if (this.data.name != null) { return; }
    const data = _.pick(LevelsNode.levels[this.keyForParent].attributes, Campaign.denormalizedLevelProperties);
    // Mark a level as internally released by default, so that we do not accidentally release a level externally.
    if (utils.isOzaria) {
      data.releasePhase = 'internalRelease';
    }
    return _.extend(this.data, data);
  }
}
LevelNode.initClass();

class NextLevelNode extends LevelNode {
  populateData() {
    if (this.data.name != null) { return; }
    const data = _.pick(LevelsNode.levels[this.keyForParent].attributes, Campaign.nextLevelProperties);
    return _.extend(this.data, data);
  }
}

class CocoCampaignsNode extends TreemaObjectNode {
  constructor(...args) {
    this.childSource = this.childSource.bind(this);
    super(...args);
  }

  static initClass() {
    this.prototype.valueClass = 'treema-campaigns';
    this.campaigns = {};
  }

  buildValueForDisplay(valEl, data) {
    return this.buildValueForDisplaySimply(valEl, ''+_.size(data));
  }

  childPropertiesAvailable() { return this.childSource; }

  childSource(req, res) {
    const s = new Backbone.Collection([], {model:Campaign});
    s.url = '/db/campaign';
    s.fetch({data: {term:req.term, project: Campaign.denormalizedCampaignProperties}});
    return s.once('sync', function(collection) {
      for (var campaign of Array.from(collection.models)) { CampaignsNode.campaigns[campaign.id] = campaign; }
      const mapped = (Array.from(collection.models).map((r) => ({label: r.get('name'), value: r.id})));
      return res(mapped);
    });
  }
}
CocoCampaignsNode.initClass();

class OzarCampaignsNode extends TreemaObjectNode {
  static initClass() {
    this.prototype.valueClass = 'treema-campaigns';
    this.campaigns = {};
    this.mapped = [];
  }

  constructor(...args) {
    this.childSource = this.childSource.bind(this);
    super(...Array.from(args || []));
    const s = new Backbone.Collection([], {model:Campaign});
    s.url = '/db/campaign';
    s.fetch({data: {project: Campaign.denormalizedCampaignProperties}});
    s.once('sync', function(collection) {
      for (var campaign of Array.from(collection.models)) { CampaignsNode.campaigns[campaign.id] = campaign; }
      return this.mapped = (Array.from(collection.models).map((r) => ({label: r.get('name'), value: r.id})));
    });
  }

  buildValueForDisplay(valEl, data) {
    return this.buildValueForDisplaySimply(valEl, ''+_.size(data));
  }

  childPropertiesAvailable() { return this.childSource; }

  childSource(req, res) {
    // Sort the results. Prioritize names that start with the search term, then contain the search term.
    const lowerTerm = req.term.toLowerCase();
    const sorted = _.filter(this.mapped, item => _.string.contains(item.label.toLowerCase(), lowerTerm));
    const startsWithTerm = _.filter(sorted, item => _.string.startsWith(item.label.toLowerCase(), lowerTerm));
    _.pull(sorted, ...Array.from(startsWithTerm));
    return res(_.flatten([startsWithTerm, sorted]));
  }
}
OzarCampaignsNode.initClass();


class CampaignNode extends TreemaObjectNode {
  static initClass() {
    this.prototype.valueClass = 'treema-campaign';
  }
  buildValueForDisplay(valEl, data) {
    return this.buildValueForDisplaySimply(valEl, data.name);
  }

  populateData() {
    if (this.data.name != null) { return; }
    // TODO: Need to be able to update i18n links to other campaigns
    const data = _.pick(CampaignsNode.campaigns[this.keyForParent].attributes, Campaign.denormalizedCampaignProperties);
    return _.extend(this.data, data);
  }
}
CampaignNode.initClass();

class AchievementNode extends treemaExt.IDReferenceNode {
  buildSearchURL(term) { return `${this.url}?term=${term}&project=${achievementProject.join(',')}`; }

  buildValueForDisplay(valEl, data) {
    super.buildValueForDisplay(valEl, data);
    return addAchievementEditorLink(this, valEl, data);
  }
}

class RewardsNode extends TreemaArrayNode {
  buildValueForDisplay(valEl, data) {
    super.buildValueForDisplay(valEl, data);
    let achievements = globalVar.currentView.achievements.where({related: this.parent.data.original});
    achievements = _.sortBy(achievements, function(a) { let left;
    return (left = __guard__(__guard__(a.get('rewards'), x1 => x1.levels), x => x.length)) != null ? left : 0; });
    const mainAchievement = achievements[0];
    if (!mainAchievement) { return; }
    return addAchievementEditorLink(this, valEl, mainAchievement.id);
  }
}

var addAchievementEditorLink = function(node, valEl, achievementId) {
  const anchor = $('<a class="spl">(e)</a>');
  anchor.on('click', function(event) {
    const childWindow = window.open(`/editor/achievement/${achievementId}`, achievementId, 'width=1040,height=900,left=1600,top=0,location=1,menubar=1,scrollbars=1,status=0,titlebar=1,toolbar=1', true);
    childWindow.achievementSavedCallback = event => node.callbacks.achievementUpdated({achievement: event.achievement}, node);
    childWindow.focus();
    return event.stopPropagation();
  });
  return valEl.find('.treema-shortened').append(anchor);
};

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}