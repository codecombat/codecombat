/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS104: Avoid inline assignments
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let LeaderboardModal;
require('app/styles/play/modal/leaderboard-modal.sass');
const ModalView = require('views/core/ModalView');
const template = require('app/templates/play/modal/leaderboard-modal');
const LeaderboardTabView = require('views/play/modal/LeaderboardTabView');
const Level = require('models/Level');
const utils = require('core/utils');

module.exports = (LeaderboardModal = (function() {
  LeaderboardModal = class LeaderboardModal extends ModalView {
    static initClass() {
      this.prototype.id = 'leaderboard-modal';
      this.prototype.template = template;
      this.prototype.instant = true;
      this.prototype.timespans = ['latest', 'all'];
  
      this.prototype.subscriptions = {};
  
      this.prototype.events = {
        'shown.bs.tab #leaderboard-nav a': 'onTabShown',
        'click #close-modal': 'hide'
      };
    }

    constructor(options) {
      super(options);
      this.levelSlug = this.options.levelSlug;
      const level = new Level({_id: this.levelSlug});
      level.project = ['name', 'i18n', 'scoreType', 'original'];
      this.level = this.supermodel.loadModel(level).model;
    }

    getRenderData(c) {
      let left;
      c = super.getRenderData(c);
      c.submenus = [];
      for (var scoreType of Array.from((left = this.level.get('scoreTypes')) != null ? left : [])) {
        if (scoreType.type) { scoreType = scoreType.type; }
        for (var timespan of Array.from(this.timespans)) {
          c.submenus.push({scoreType, timespan});
        }
      }
      c.levelName = utils.i18n(this.level.attributes, 'name');
      return c;
    }

    afterRender() {
      let left;
      super.afterRender();
      if (!this.supermodel.finished()) { return; }
      const iterable = (left = this.level.get('scoreTypes')) != null ? left : [];
      for (let scoreTypeIndex = 0; scoreTypeIndex < iterable.length; scoreTypeIndex++) {
        var scoreType = iterable[scoreTypeIndex];
        if (scoreType.type) { scoreType = scoreType.type; }
        for (var timespanIndex = 0; timespanIndex < this.timespans.length; timespanIndex++) {
          var timespan = this.timespans[timespanIndex];
          var submenuView = new LeaderboardTabView({scoreType, timespan, level: this.level});
          this.insertSubView(submenuView, this.$el.find(`#${scoreType}-${timespan}-view .leaderboard-tab-view`));
          if ((scoreTypeIndex + timespanIndex) === 0) {
            submenuView.$el.parent().addClass('active');
            if (typeof submenuView.onShown === 'function') {
              submenuView.onShown();
            }
          }
        }
      }
      this.playSound('game-menu-open');
      return this.$el.find('.nano:visible').nanoScroller();
    }

    onTabShown(e) {
      this.playSound('game-menu-tab-switch');
      const tabChunks = e.target.hash.substring(1).split('-');
      const scoreType = tabChunks.slice(0 ,  tabChunks.length - 2).join('-');
      const timespan = tabChunks[tabChunks.length - 2];
      const subview = _.find(this.subviews, {scoreType, timespan});
      if (typeof subview.onShown === 'function') {
        subview.onShown();
      }
      return (() => {
        const result = [];
        for (var subviewKey in this.subviews) {
          var otherSubview = this.subviews[subviewKey];
          if (otherSubview !== subview) {
            result.push((typeof otherSubview.onHidden === 'function' ? otherSubview.onHidden() : undefined));
          }
        }
        return result;
      })();
    }

    onHidden() {
      super.onHidden();
      for (var subviewKey in this.subviews) { var subview = this.subviews[subviewKey]; if (typeof subview.onHidden === 'function') {
        subview.onHidden();
      } }
      return this.playSound('game-menu-close');
    }
  };
  LeaderboardModal.initClass();
  return LeaderboardModal;
})());
