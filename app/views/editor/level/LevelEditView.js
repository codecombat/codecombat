// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let LevelEditView;
require('app/styles/editor/level/documentation_tab.sass');
const RootView = require('views/core/RootView');
const template = require('app/templates/editor/level/level-edit-view');
const Level = require('models/Level');
const LevelSystem = require('models/LevelSystem');
const LevelComponent = require('models/LevelComponent');
const LevelSystems = require('collections/LevelSystems');
const LevelComponents = require('collections/LevelComponents');
const World = require('lib/world/world');
const DocumentFiles = require('collections/DocumentFiles');
const LevelLoader = require('lib/LevelLoader');

const Campaigns = require('collections/Campaigns');
const CocoCollection = require('collections/CocoCollection');
const Course = require('models/Course');

const RevertModal = require('views/modal/RevertModal');
const GenerateTerrainModal = require('views/editor/level/modals/GenerateTerrainModal');

const ThangsTabView = require('./thangs/ThangsTabView');
const SettingsTabView = require('./settings/SettingsTabView');
const ScriptsTabView = require('./scripts/ScriptsTabView');
const ComponentsTabView = require('./components/ComponentsTabView');
const SystemsTabView = require('./systems/SystemsTabView');
const KeyThangTabView = require('./thangs/KeyThangTabView');
const TasksTabView = require('./tasks/TasksTabView');
const SaveLevelModal = require('./modals/SaveLevelModal');
const ArtisanGuideModal = require('./modals/ArtisanGuideModal');
const ForkModal = require('views/editor/ForkModal');
const SaveVersionModal = require('views/editor/modal/SaveVersionModal');
const SaveBranchModal = require('views/editor/level/modals/SaveBranchModal');
const LoadBranchModal = require('views/editor/level/modals/LoadBranchModal');
const PatchesView = require('views/editor/PatchesView');
const RelatedAchievementsView = require('views/editor/level/RelatedAchievementsView');
const VersionHistoryView = require('./modals/LevelVersionsModal');
const ComponentsDocumentationView = require('views/editor/docs/ComponentsDocumentationView');
const SystemsDocumentationView = require('views/editor/docs/SystemsDocumentationView');
const LevelFeedbackView = require('views/editor/level/LevelFeedbackView');
const storage = require('core/storage');
const utils = require('core/utils');
const loadAetherLanguage = require('lib/loadAetherLanguage');
const presenceApi = require(utils.isOzaria ? '../../../../ozaria/site/api/presence' : 'core/api/presence');
const globalVar = require('core/globalVar');

require('vendor/scripts/coffeescript'); // this is tenuous, since the LevelSession and LevelComponent models are what compile the code
require('lib/setupTreema');

// Make sure that all of our languages are loaded, so that if we try to preview the level, it will work.
require('bower_components/aether/build/html');
Promise.all(
  ["javascript", "python", "coffeescript", "lua"].map(
    loadAetherLanguage
  )
);
require('lib/game-libraries');

module.exports = (LevelEditView = (function() {
  LevelEditView = class LevelEditView extends RootView {
    static initClass() {
      this.prototype.id = 'editor-level-view';
      this.prototype.className = 'editor';
      this.prototype.template = template;
      this.prototype.cache = false;

      this.prototype.events = {
        'click #play-button': 'onPlayLevel',
        'click .play-with-team-button': 'onPlayLevel',
        'click .play-with-team-parent': 'onPlayLevelTeamSelect',
        'click .play-classroom-level': 'onPlayLevel',
        'click #commit-level-start-button': 'startCommittingLevel',
        'click li:not(.disabled) > #fork-start-button': 'startForking',
        'click #level-history-button': 'showVersionHistory',
        'click #undo-button': 'onUndo',
        'mouseenter #undo-button': 'showUndoDescription',
        'click #redo-button': 'onRedo',
        'mouseenter #redo-button': 'showRedoDescription',
        'click #patches-tab'() { return this.patchesView.load(); },
        'click #components-tab'() { return this.subviews.editor_level_components_tab_view.refreshLevelThangsTreema(this.level.get('thangs')); },
        'click #artisan-guide-button': 'showArtisanGuide',
        'click #level-patch-button': 'startPatchingLevel',
        'click #level-watch-button': 'toggleWatchLevel',
        'click li:not(.disabled) > #pop-level-i18n-button': 'onPopulateI18N',
        'click a[href="#editor-level-documentation"]': 'onClickDocumentationTab',
        'click #save-branch': 'onClickSaveBranch',
        'click #load-branch': 'onClickLoadBranch',
        'mouseup .nav-tabs > li a': 'toggleTab',
        'click [data-toggle="coco-modal"][data-target="modal/RevertModal"]': 'openRevertModal',
        'click [data-toggle="coco-modal"][data-target="editor/level/modals/GenerateTerrainModal"]': 'openGenerateTerrainModal'
      };

      this.prototype.subscriptions =
        {'editor:thang-deleted': 'onThangDeleted'};
    }

    constructor(options, levelID) {
      super(options);
      this.incrementBuildTime = this.incrementBuildTime.bind(this);
      this.checkPresence = this.checkPresence.bind(this);
      this.levelID = levelID;
      this.supermodel.shouldSaveBackups = model => ['Level', 'LevelComponent', 'LevelSystem', 'ThangType'].includes(model.constructor.className);
      this.levelLoader = new LevelLoader({supermodel: this.supermodel, levelID: this.levelID, headless: true, sessionless: true, loadArticles: true});
      this.level = this.levelLoader.level;
      this.files = new DocumentFiles(this.levelLoader.level);
      this.supermodel.loadCollection(this.files, 'file_names');
      this.campaigns = new Campaigns();
      this.supermodel.trackRequest(this.campaigns.fetchByType('course', { data: { project: 'levels' } }));
      this.courses = new CocoCollection([], { url: "/db/course", model: Course});
      this.supermodel.loadCollection(this.courses, 'courses');
    }

    getMeta() {
      let title = $.i18n.t('editor.level_title');
      let levelName = utils.i18n(((this.level != null ? this.level.attributes : undefined) || {}), 'displayname');
      if (!levelName) { levelName = utils.i18n(((this.level != null ? this.level.attributes : undefined) || {}), 'name'); }
      if (levelName) {
        title = levelName + ' - ' + title;
      }
      return {title};
    }

    destroy() {
      // Currently only check presence on the level.
      // TODO: Should this system also handle other models with local backups: 'LevelComponent', 'LevelSystem', 'ThangType'
      if ((!this.level.hasLocalChanges()) && me.isAdmin()) {
        presenceApi.deletePresence({levelOriginalId: this.level.get('original')});
      }

      clearInterval(this.timerIntervalID);
      clearInterval(this.checkPresenceIntervalID);
      return super.destroy();
    }

    showLoading($el) {
      if ($el == null) { $el = this.$el.find('.outer-content'); }
      return super.showLoading($el);
    }

    onLoaded() {
      _.defer(() => {
        this.setMeta(this.getMeta());
        this.world = this.levelLoader.world;
        this.render();
        this.timerIntervalID = setInterval(this.incrementBuildTime, 1000);
        if (this.level.get('original')) {
          this.checkPresenceIntervalID = setInterval(this.checkPresence, 15000);
          this.checkPresence();
          if (me.isAdmin()) {
            return presenceApi.setPresence({ levelOriginalId: this.level.get('original') });
          }
        }
      });

      const campaignCourseMap = {};
      for (var course of Array.from(this.courses.models)) { campaignCourseMap[course.get('campaignID')] = course.id; }
      for (var campaign of Array.from(this.campaigns.models)) {
        var object = campaign.get('levels');
        for (var levelID in object) {
          var level = object[levelID];
          if (levelID === this.level.get('original')) {
            this.courseID = campaignCourseMap[campaign.id];
          }
        }
        if (this.courseID) { break; }
      }
      if (!this.courseID && (me.isAdmin() || me.isArtisan())) {
        // Give it a fake course ID so we can test it in course mode before it's in a course.
        this.courseID = '560f1a9f22961295f9427742';
      }
      return this.getLevelCompletionRate();
    }

    getRenderData(context) {
      let left;
      if (context == null) { context = {}; }
      context = super.getRenderData(context);
      context.level = this.level;
      context.authorized = me.isAdmin() || this.level.hasWriteAccess(me);
      context.anonymous = me.get('anonymous');
      context.recentlyPlayedOpponents = (left = __guard__(storage.load('recently-played-matches'), x => x[this.levelID])) != null ? left : [];
      return context;
    }

    afterRender() {
      super.afterRender();
      if (!this.supermodel.finished()) { return; }
      this.listenTo(this.level, 'change:tasks', () => this.renderSelectors('#tasks-tab'));
      this.thangsTabView = this.insertSubView(new ThangsTabView({world: this.world, supermodel: this.supermodel, level: this.level}));
      this.insertSubView(new SettingsTabView({supermodel: this.supermodel}));
      this.insertSubView(new ScriptsTabView({world: this.world, supermodel: this.supermodel, files: this.files}));
      this.insertSubView(new ComponentsTabView({supermodel: this.supermodel}));
      this.insertSubView(new SystemsTabView({supermodel: this.supermodel, world: this.world}));
      this.insertKeyThangTabViews();
      this.insertSubView(new TasksTabView({world: this.world, supermodel: this.supermodel, level: this.level}));
      this.insertSubView(new RelatedAchievementsView({supermodel: this.supermodel, level: this.level}));
      this.insertSubView(new ComponentsDocumentationView({lazy: true}));  // Don't give it the supermodel, it'll pollute it!
      this.insertSubView(new SystemsDocumentationView({lazy: true}));  // Don't give it the supermodel, it'll pollute it!
      this.insertSubView(new LevelFeedbackView({level: this.level}));
      this.$el.find('a[data-toggle="tab"]').on('shown.bs.tab', e => {
        return Backbone.Mediator.publish('editor:view-switched', {targetURL: $(e.target).attr('href')});
    });

      Backbone.Mediator.publish('editor:level-loaded', {level: this.level});
      if (me.get('anonymous')) { this.showReadOnly(); }
      this.patchesView = this.insertSubView(new PatchesView(this.level), this.$el.find('.patches-view'));
      this.listenTo(this.patchesView, 'accepted-patch', function(attrs) {
        if (attrs != null ? attrs.save : undefined) {
          const f = () => this.startCommittingLevel(attrs);
          return setTimeout(f, 400); // Give some time for closing patch modal
        } else {
          if (!key.shift) { return location.reload(); }
        }
      });  // Reload to make sure changes propagate, unless secret shift shortcut
      if (this.level.watching()) { return this.$el.find('#level-watch-button').find('> span').toggleClass('secret'); }
    }

    insertKeyThangTabViews() {
      if (this.keyThangTabViews == null) { this.keyThangTabViews = {}; }
      this.keyThangIDs = ['Hero Placeholder', 'Hero Placeholder 1', 'Referee', 'RefereeJS', 'Level Manager', 'Level Manager JS'].reverse();
      for (var id of Array.from(this.keyThangIDs)) {
        var left, thang;
        if (!(thang = _.find((left = this.level.get('thangs')) != null ? left : [], {id}))) { continue; }
        if (this.keyThangTabViews[id]) { continue; }
        var thangPath = this.thangsTabView.pathForThang(thang);
        var tabId = `key-thang-tab-view-${_.string.slugify(thang.id)}`;
        var tabName = id.replace(/ ?(Placeholder|JS|Level)/g, '');
        var $subView = new KeyThangTabView({thangData: thang, level: this.level, world: this.world, supermodel: this.supermodel, oldPath: thangPath, id: tabId});
        $subView.$el.insertAfter(this.$el.find('#systems-tab-view'));
        $subView.render();
        $subView.afterInsert();
        this.keyThangTabViews[id] = this.registerSubView($subView);
        var $tabBarEntry = $(`<li><a data-toggle='tab' href='#${tabId}'>${tabName}</a></li>`);
        $tabBarEntry.insertAfter(this.$el.find('a[href="#systems-tab-view"]').parent());
      }
      return null;
    }

    onThangDeleted(e) {
      if (!Array.from(this.keyThangIDs != null ? this.keyThangIDs : []).includes(e.thangID)) { return; }
      this.removeSubView(this.keyThangTabViews[e.thangID]);
      return this.keyThangTabViews[e.thangID] = null;
    }

    openRevertModal(e) {
      e.stopPropagation();
      return this.openModalView(new RevertModal());
    }

    openGenerateTerrainModal(e) {
      e.stopPropagation();
      return this.openModalView(new GenerateTerrainModal());
    }

    onPlayLevelTeamSelect(e) {
      if (this.childWindow && !this.childWindow.closed) {
        // We already have a child window open, so we don't need to ask for a team; we'll use its existing team.
        e.stopImmediatePropagation();
        return this.onPlayLevel(e);
      }
    }

    onPlayLevel(e) {
      let left, newClassMode;
      const team = $(e.target).data('team');
      const opponentSessionID = $(e.target).data('opponent');
      if ($(e.target).data('classroom') === 'home') {
        newClassMode = (this.lastNewClassMode = undefined);
      } else if ($(e.target).data('classroom')) {
        newClassMode = (this.lastNewClassMode = true);
      } else {
        newClassMode = this.lastNewClassMode;
      }
      const newClassLanguage = (this.lastNewClassLanguage = ((left = $(e.target).data('code-language')) != null ? left : this.lastNewClassLanguage) || undefined);
      if (utils.isOzaria && this.childWindow && (this.childWindow.closed || !this.childWindow.onPlayLevelViewLoaded)) {
        __guardMethod__(this.childWindow, 'close', o => o.close());
        return noty({timeout: 4000, text: 'Error: child window disconnected, you will have to reload this page to preview.', type: 'error', layout: 'top'});
      }
      const sendLevel = () => {
        return this.childWindow.Backbone.Mediator.publish('level:reload-from-data', {level: this.level, supermodel: this.supermodel});
      };
      if (this.childWindow && !this.childWindow.closed && (this.playClassMode === newClassMode) && (this.playClassLanguage === newClassLanguage)) {
        // Reset the LevelView's world, but leave the rest of the state alone
        sendLevel();
      } else {
        // Create a new Window with a blank LevelView
        let scratchLevelID = this.level.get('slug') + '?dev=true';
        if (team) { scratchLevelID += `&team=${team}`; }
        if (opponentSessionID) { scratchLevelID += `&opponent=${opponentSessionID}`; }
        this.playClassMode = newClassMode;
        this.playClassLanguage = newClassLanguage;
        if (this.playClassMode) {
          scratchLevelID += `&course=${this.courseID}`;
          scratchLevelID += `&codeLanguage=${this.playClassLanguage}`;
        }
        if (utils.isOzaria) {
          this.childWindow = window.open(`/play/level/${scratchLevelID}`, 'child_window');
        } else if (me.get('name') === 'Nick') {
          this.childWindow = window.open(`/play/level/${scratchLevelID}`, 'child_window', 'width=2560,height=1080,left=0,top=-1600,location=1,menubar=1,scrollbars=1,status=0,titlebar=1,toolbar=1', true);
        } else {
          this.childWindow = window.open(`/play/level/${scratchLevelID}`, 'child_window', 'width=1280,height=640,left=10,top=10,location=0,menubar=0,scrollbars=0,status=0,titlebar=0,toolbar=0', true);
        }
        this.childWindow.onPlayLevelViewLoaded = e => sendLevel();  // still a hack
      }
      return this.childWindow.focus();
    }

    onUndo() {
      return __guard__(TreemaNode.getLastTreemaWithFocus(), x => x.undo());
    }

    onRedo() {
      return __guard__(TreemaNode.getLastTreemaWithFocus(), x => x.redo());
    }

    showUndoDescription() {
      const undoDescription = TreemaNode.getLastTreemaWithFocus().getUndoDescription();
      return this.$el.find('#undo-button').attr('title', $.i18n.t("general.undo_prefix") + " " + undoDescription + " " + $.i18n.t("general.undo_shortcut"));
    }

    showRedoDescription() {
      const redoDescription = TreemaNode.getLastTreemaWithFocus().getRedoDescription();
      return this.$el.find('#redo-button').attr('title', $.i18n.t("general.redo_prefix") + " " + redoDescription + " " + $.i18n.t("general.redo_shortcut"));
    }

    getCurrentView() {
      let currentViewID = this.$el.find('.tab-pane.active').attr('id');
      if (currentViewID === 'editor-level-patches') { return this.patchesView; }
      if (currentViewID === 'editor-level-documentation') { currentViewID = 'components-documentation-view'; }
      return this.subviews[_.string.underscored(currentViewID)];
    }

    startPatchingLevel(e) {
      this.openModalView(new SaveVersionModal({model: this.level}));
      return Backbone.Mediator.publish('editor:view-switched', {});
    }

    startCommittingLevel(e) {
      this.openModalView(new SaveLevelModal({level: this.level, supermodel: this.supermodel, buildTime: this.levelBuildTime, commitMessage: (e != null ? e.commitMessage : undefined)}));
      return Backbone.Mediator.publish('editor:view-switched', {});
    }

    showArtisanGuide(e) {
      this.openModalView(new ArtisanGuideModal({level: this.level}));
      return Backbone.Mediator.publish('editor:view-switched', {});
    }

    startForking(e) {
      this.openModalView(new ForkModal({model: this.level, editorPath: 'level'}));
      return Backbone.Mediator.publish('editor:view-switched', {});
    }

    showVersionHistory(e) {
      const versionHistoryView = new VersionHistoryView({level: this.level}, this.levelID);
      this.openModalView(versionHistoryView);
      return Backbone.Mediator.publish('editor:view-switched', {});
    }

    toggleWatchLevel() {
      const button = this.$el.find('#level-watch-button');
      this.level.watch(button.find('.watch').is(':visible'));
      return button.find('> span').toggleClass('secret');
    }

    onPopulateI18N() {
      let totalChanges = this.level.populateI18N();

      const levelComponentMap = _(globalVar.currentView.supermodel.getModels(LevelComponent))
        .map(c => [c.get('original'), c])
        .object()
        .value();

      const iterable = this.level.get('thangs');
      for (let thangIndex = 0; thangIndex < iterable.length; thangIndex++) {
        var thang = iterable[thangIndex];
        for (var thangComponentIndex = 0; thangComponentIndex < thang.components.length; thangComponentIndex++) {
          var thangComponent = thang.components[thangComponentIndex];
          var component = levelComponentMap[thangComponent.original];
          var configSchema = component.get('configSchema');
          var path = `/thangs/${thangIndex}/components/${thangComponentIndex}/config`;
          totalChanges += this.level.populateI18N(thangComponent.config, configSchema, path);
        }
      }

      if (totalChanges) {
        const f = () => document.location.reload();
        return setTimeout(f, 500);
      } else {
        return noty({timeout: 2000, text: 'No changes.', type: 'information', layout: 'topRight'});
      }
    }

    onClickSaveBranch() {
      const components = new LevelComponents(this.supermodel.getModels(LevelComponent));
      const systems = new LevelSystems(this.supermodel.getModels(LevelSystem));
      this.openModalView(new SaveBranchModal({components, systems}));
      return Backbone.Mediator.publish('editor:view-switched', {});
    }

    onClickLoadBranch() {
      const components = new LevelComponents(this.supermodel.getModels(LevelComponent));
      const systems = new LevelSystems(this.supermodel.getModels(LevelSystem));
      this.openModalView(new LoadBranchModal({components, systems}));
      return Backbone.Mediator.publish('editor:view-switched', {});
    }

    toggleTab(e) {
      this.renderScrollbar();
      if (!($(document).width() <= 800)) { return; }
      const li = $(e.target).closest('li');
      if (li.hasClass('active')) {
        li.parent().find('li').show();
      } else {
        li.parent().find('li').hide();
        li.show();
      }
      return console.log(li.hasClass('active'));
    }

    onClickDocumentationTab(e) {
      // It's either too late at night or something is going on with Bootstrap nested tabs, so we do the click instead of using .active.
      if (this.initializedDocs) { return; }
      this.initializedDocs = true;
      return this.$el.find('a[href="#components-documentation-view"]').click();
    }

    incrementBuildTime() {
      if (application.userIsIdle) { return; }
      if (this.levelBuildTime == null) { let left;
      this.levelBuildTime = (left = this.level.get('buildTime')) != null ? left : 0; }
      return ++this.levelBuildTime;
    }

    checkPresence() {
      if (!this.level.get('original')) { return; }
      return presenceApi.getPresence({levelOriginalId: this.level.get('original')})
        .then(this.updatePresenceUI)
        .catch(this.updatePresenceUI);
    }

    updatePresenceUI(emails) {
      $("#dropdownPresenceMenu").empty();
      if (!Array.isArray(emails)) {
        $("#presence-number").text("?");
        return;
      }
      if (emails == null) { emails = []; }
      $("#presence-number").text(emails.length || 0);
      return emails.forEach(email => $("#dropdownPresenceMenu").append(`<li>${email}</li>`));
    }

    getTaskCompletionRatio() {
      if ((this.level.get('tasks') == null)) {
        return '0/0';
      } else {
        return _.filter(this.level.get('tasks'), _elem => _elem.complete).length + '/' + this.level.get('tasks').length;
      }
    }

    getLevelCompletionRate() {
      if (!me.isAdmin()) { return; }
      const startDay = utils.getUTCDay(-14);
      const startDayDashed = `${startDay.slice(0, 4)}-${startDay.slice(4, 6)}-${startDay.slice(6, 8)}`;
      const endDay = utils.getUTCDay(-1);
      const endDayDashed = `${endDay.slice(0, 4)}-${endDay.slice(4, 6)}-${endDay.slice(6, 8)}`;
      const success = data => {
        if (this.destroyed) { return; }
        let started = 0;
        let finished = 0;
        for (var day of Array.from(data)) {
          started += day.started != null ? day.started : 0;
          finished += day.finished != null ? day.finished : 0;
        }
        const rate = finished / started;
        const rateDisplay = (rate * 100).toFixed(1) + '%';
        return this.$('#completion-rate').text(rateDisplay);
      };
      const request = this.supermodel.addRequestResource('level_completions', {
        url: '/db/analytics_perday/-/level_completions',
        data: {startDay, endDay, slug: this.level.get('slug')},
        method: 'POST',
        success
      }, 0);
      return request.load();
    }
  };
  LevelEditView.initClass();
  return LevelEditView;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}
function __guardMethod__(obj, methodName, transform) {
  if (typeof obj !== 'undefined' && obj !== null && typeof obj[methodName] === 'function') {
    return transform(obj, methodName);
  } else {
    return undefined;
  }
}