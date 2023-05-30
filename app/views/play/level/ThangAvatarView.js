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
let ThangAvatarView;
const CocoView = require('views/core/CocoView');
const template = require('app/templates/play/level/thang_avatar');
const ThangType = require('models/ThangType');

module.exports = (ThangAvatarView = (function() {
  ThangAvatarView = class ThangAvatarView extends CocoView {
    static initClass() {
      this.prototype.className = 'thang-avatar-view';
      this.prototype.template = template;
  
      this.prototype.subscriptions = {
        'tome:problems-updated': 'onProblemsUpdated',
        'god:new-world-created': 'onNewWorld'
      };
    }

    constructor(options) {
      super(options);
      this.thang = options.thang;
      this.includeName = options.includeName;
      this.thangType = this.getSpriteThangType();
      if (!this.thangType) {
        console.error('Thang avatar view expected a thang type to be provided.');
        return;
      }

      if (!this.thangType.isFullyLoaded() && !this.thangType.loading) {
        this.thangType.fetch();
      }

      // couldn't get the level view to load properly through the supermodel
      // so just doing it manually this time.
      this.listenTo(this.thangType, 'sync', this.render);
      this.listenTo(this.thangType, 'build-complete', this.render);
    }

    getSpriteThangType() {
      let t;
      let thangs = this.supermodel.getModels(ThangType);
      thangs = ((() => {
        const result = [];
        for (t of Array.from(thangs)) {           if (t.get('name') === this.thang.spriteName) {
            result.push(t);
          }
        }
        return result;
      })());
      const loadedThangs = ((() => {
        const result1 = [];
        for (t of Array.from(thangs)) {           if (t.isFullyLoaded()) {
            result1.push(t);
          }
        }
        return result1;
      })());
      return loadedThangs[0] || thangs[0]; // try to return one with all the goods, otherwise a projection
    }

    getRenderData(context) {
      if (context == null) { context = {}; }
      context = super.getRenderData(context);
      context.thang = this.thang;
      const options = (this.thang != null ? this.thang.getLankOptions() : undefined) || {};
      //options.async = true  # sync builds fail during async builds, and we build HUD version sync
      if (!this.thangType.loading) { context.avatarURL = this.thangType.getPortraitSource(options); }
      context.includeName = this.includeName;
      return context;
    }

    setProblems(problemCount, level) {
      const badge = this.$el.find('.badge.problems').text(problemCount ? 'x' : '');
      badge.removeClass('error warning info');
      if (level) { return badge.addClass(level); }
    }

    setSharedThangs(sharedThangCount) {
      let badge;
      return badge = this.$el.find('.badge.shared-thangs').text(sharedThangCount > 1 ? sharedThangCount : '');
    }
      // TODO: change the alert color based on whether any of those things that aren't us have problems
      //badge.removeClass('error warning info')
      //badge.addClass level if level

    setSelected(selected) {
      return this.$el.toggleClass('selected', Boolean(selected));
    }

    onProblemsUpdated(e) {
      let left;
      if ((this.thang != null ? this.thang.id : undefined) !== (e.spell.thang != null ? e.spell.thang.thang.id : undefined)) { return; }
      const aether = e.spell.thang.castAether;
      const myProblems = (left = (aether != null ? aether.getAllProblems() : undefined)) != null ? left : [];
      let worstLevel = null;
      for (var level of ['error', 'warning', 'info']) {
        if (_.some(myProblems, {level})) {
          worstLevel = level;
          break;
        }
      }
      return this.setProblems(myProblems.length, worstLevel);
    }

    onNewWorld(e) {
      if (this.thang && e.world.thangMap[this.thang.id]) { return this.options.thang = (this.thang = e.world.thangMap[this.thang.id]); }
    }

    destroy() {
      return super.destroy();
    }
  };
  ThangAvatarView.initClass();
  return ThangAvatarView;
})());
