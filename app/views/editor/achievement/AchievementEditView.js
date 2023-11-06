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
let AchievementEditView;
require('app/styles/editor/achievement/edit.sass');
const RootView = require('views/core/RootView');
const template = require('app/templates/editor/achievement/edit');
const Achievement = require('models/Achievement');
const Level = require('models/Level');
const AchievementPopup = require('views/core/AchievementPopup');
const ConfirmModal = require('views/core/ConfirmModal');
const PatchesView = require('views/editor/PatchesView');
const errors = require('core/errors');
const nodes = require('views/editor/level/treema_nodes');

require('lib/game-libraries');

module.exports = (AchievementEditView = (function() {
  AchievementEditView = class AchievementEditView extends RootView {
    static initClass() {
      this.prototype.id = 'editor-achievement-edit-view';
      this.prototype.template = template;

      this.prototype.events = {
        'click #save-button': 'saveAchievement',
        'click #recalculate-button': 'confirmRecalculation',
        'click #recalculate-all-button': 'confirmAllRecalculation',
        'click #delete-button': 'confirmDeletion'
      };
    }

    constructor(options, achievementID) {
      super(options);
      this.pushChangesToPreview = this.pushChangesToPreview.bind(this);
      this.recalculateAchievement = this.recalculateAchievement.bind(this);
      this.deleteAchievement = this.deleteAchievement.bind(this);
      this.achievementID = achievementID;
      this.achievement = new Achievement({_id: this.achievementID});
      this.achievement.saveBackups = true;
      this.supermodel.trackRequest(this.achievement.fetch());

      // load level names so they're available to treema nodes
      this.listenToOnce(this.achievement, 'sync', function() {
        return (() => {
          let left;
          const result = [];
          for (var levelOriginal of Array.from((left = __guard__(this.achievement.get('rewards'), x => x.levels)) != null ? left : [])) {
            var level = new Level();
            this.supermodel.trackRequest(level.fetchLatestVersion(levelOriginal, {data: {project:'name,version,original'}}));
            result.push(level.once('sync', level => this.supermodel.registerModel(level)));
          }
          return result;
        })();
      });

      this.pushChangesToPreview = _.throttle(this.pushChangesToPreview, 500);
    }

    onLoaded() {
      super.onLoaded();
      this.buildTreema();
      return this.listenTo(this.achievement, 'change', () => {
        this.achievement.updateI18NCoverage();
        return this.treema.set('/', this.achievement.attributes);
      });
    }

    buildTreema() {
      if ((this.treema != null) || (!this.achievement.loaded)) { return; }
      const data = $.extend(true, {}, this.achievement.attributes);
      const options = {
        data,
        filePath: `db/achievement/${this.achievement.get('_id')}`,
        schema: Achievement.schema,
        readOnly: me.get('anonymous'),
        callbacks: {
          change: this.pushChangesToPreview
        },
        nodeClasses: {
          'thang-type': nodes.ThangTypeNode,
          'item-thang-type': nodes.ItemThangTypeNode
        },
        supermodel: this.supermodel
      };
      this.treema = this.$el.find('#achievement-treema').treema(options);
      this.treema.build();
      if (this.treema.childrenTreemas.rewards != null) {
        this.treema.childrenTreemas.rewards.open(3);
      }
      return this.pushChangesToPreview();
    }

    afterRender() {
      super.afterRender();
      if (!this.supermodel.finished()) { return; }
      if (me.get('anonymous')) { this.showReadOnly(); }
      this.pushChangesToPreview();
      this.patchesView = this.insertSubView(new PatchesView(this.achievement), this.$el.find('.patches-view'));
      return this.patchesView.load();
    }

    pushChangesToPreview() {
      let popup;
      if (!this.treema) { return; }
      this.$el.find('#achievement-view').empty();
      for (var key in this.treema.data) {
        var value = this.treema.data[key];
        this.achievement.set(key, value);
      }
      const earned = {get: key => ({earnedPoints: this.achievement.get('worth'), previouslyAchievedAmount: 0}[key])};
      return popup = new AchievementPopup({achievement: this.achievement, earnedAchievement: earned, popup: false, container: $('#achievement-view')});
    }

    openSaveModal() {
      return 'Maybe later'; // TODO patch patch patch
    }

    saveAchievement(e) {
      this.treema.endExistingEdits();
      for (var key in this.treema.data) {
        var value = this.treema.data[key];
        this.achievement.set(key, value);
      }

      const res = this.achievement.save();

      res.error((collection, response, options) => {
        return console.error(response);
      });

      return res.success(() => {
        if (window.achievementSavedCallback) {
          // CampaignEditor is using this as a child, so let it know that we have changed something (and don't reload)
          return window.achievementSavedCallback({achievement: this.achievement});
        } else {
          const url = `/editor/achievement/${this.achievement.get('slug') || this.achievement.id}`;
          return document.location.href = url;
        }
      });
    }

    confirmRecalculation(e, all) {
      if (all == null) { all = false; }
      const renderData = {
        title: 'Are you really sure?',
        body: `This will trigger recalculation of ${all ? 'all achievements' : 'the achievement'} for all users. Are you really sure you want to go down this path?`,
        decline: 'Not really',
        confirm: 'Definitely'
      };

      const confirmModal = new ConfirmModal(renderData);
      confirmModal.on('confirm', this.recalculateAchievement);
      this.recalculatingAll = all;
      return this.openModalView(confirmModal);
    }

    confirmAllRecalculation(e) {
      return this.confirmRecalculation(e, true);
    }

    confirmDeletion() {
      const renderData = {
        title: 'Are you really sure?',
        body: 'This will completely delete the achievement, potentially breaking a lot of stuff you don\'t want breaking. Are you entirely sure?',
        decline: 'Not really',
        confirm: 'Definitely'
      };

      const confirmModal = new ConfirmModal(renderData);
      confirmModal.on('confirm', this.deleteAchievement);
      return this.openModalView(confirmModal);
    }

    recalculateAchievement() {
      const data = this.recalculatingAll ? {} : {achievements: [this.achievement.get('slug') || this.achievement.get('_id')]};
      return $.ajax({
        data: JSON.stringify(data),
        success(data, status, jqXHR) {
          return noty({
            timeout: 5000,
            text: 'Recalculation process started',
            type: 'success',
            layout: 'topCenter'
          });
        },
        error(jqXHR, status, error) {
          console.error(jqXHR);
          return noty({
            timeout: 5000,
            text: `Starting recalculation process failed with error code ${jqXHR.status}`,
            type: 'error',
            layout: 'topCenter'
          });
        },
        url: '/admin/earned.achievement/recalculate',
        type: 'POST',
        contentType: 'application/json'
      });
    }

    deleteAchievement() {
      console.debug('deleting');
      return $.ajax({
        type: 'DELETE',
        success() {
          noty({
            timeout: 5000,
            text: 'Aaaand it\'s gone.',
            type: 'success',
            layout: 'topCenter'
          });
          return _.delay(() => application.router.navigate('/editor/achievement', {trigger: true})
          , 500);
        },
        error(jqXHR, status, error) {
          console.error(jqXHR);
          return {
            timeout: 5000,
            text: `Deleting achievement failed with error code ${jqXHR.status}`,
            type: 'error',
            layout: 'topCenter'
          };
        },
        url: `/db/achievement/${this.achievement.id}`
      });
    }
  };
  AchievementEditView.initClass();
  return AchievementEditView;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}