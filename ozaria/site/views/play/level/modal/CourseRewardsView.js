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
let CourseRewardsView;
require('app/styles/play/level/modal/course-rewards-view.sass');
const CocoView = require('views/core/CocoView');
const ThangType = require('models/ThangType');
const EarnedAchievement = require('models/EarnedAchievement');
const utils = require('core/utils');
const User = require('models/User');

// This view is to show gems/xp/items earned after completing a level in classroom version.
// It is similar to that on HeroVictoryModal for home version, but excluding some which is not required here.
// TODO: Move this into a reusable component to be used by both home and classroom versions.

module.exports = (CourseRewardsView = (function() {
  CourseRewardsView = class CourseRewardsView extends CocoView {
    static initClass() {
      this.prototype.id = 'course-rewards-view';
      this.prototype.className = 'modal-content'
      this.prototype.template = require('templates/play/level/modal/course-rewards-view');

      this.prototype.events =
        { 'click #continue-btn': 'onClickContinueButton' }
    }

    constructor (options) {
      super(options)
      this.level = options.level;
      this.session = options.session
      this.thangTypes = {}
      this.achievements = options.achievements
      this.tickSequentialAnimation = this.tickSequentialAnimation.bind(this)
    }

    render () {
      this.loadAchievementsData()
      this.previousXP = me.get('points', true);
      this.previousLevel = me.level();
      return super.render();
    }

    afterRender() {
      super.afterRender();
      return this.initializeAnimations();
    }

    onClickContinueButton() {
      return this.trigger('continue');
    }

    loadAchievementsData() {
      let achievement;
      let itemOriginals = [];
      for (achievement of Array.from(this.achievements.models)) {
        var rewards = achievement.get('rewards') || {};
        itemOriginals.push(rewards.items || []);
      }

      // get the items earned from achievements
      itemOriginals = _.uniq(_.flatten(itemOriginals));
      for (var itemOriginal of Array.from(itemOriginals)) {
        var thangType = new ThangType();
        thangType.url = `/db/thang.type/${itemOriginal}/version`;
        thangType.project = ['original', 'rasterIcon', 'name', 'slug', 'soundTriggers', 'featureImages', 'gems', 'heroClass', 'description', 'components', 'extendedName', 'shortName', 'unlockLevelName', 'i18n', 'subscriber'];
        this.thangTypes[itemOriginal] = this.supermodel.loadModel(thangType).model;
      }

      this.newEarnedAchievements = [];
      for (achievement of Array.from(this.achievements.models)) {
        if (!achievement.completed) { continue; }
        var ea = new EarnedAchievement({
          collection: achievement.get('collection'),
          triggeredBy: this.session.id,
          achievement: achievement.id
        });
        if (me.isSessionless()) {
          this.newEarnedAchievements.push(ea);
        } else {
          ea.save();
          // Can't just add models to supermodel because each ea has the same url
          this.newEarnedAchievements.push(ea);
          this.listenToOnce(ea, 'sync', function(model) {
            if (_.all(((() => {
              const result = [];
              for (ea of Array.from(this.newEarnedAchievements)) {                 result.push(ea.id);
              }
              return result;
            })()))) {
              if (!me.loading) {
                this.supermodel.loadModel(me, {cache: false});
              }
              this.newEarnedAchievementsResource.markLoaded();
            }
            if (!me.loading) { return me.fetch({cache: false}); }
          });
        }
      }

      if (!me.isSessionless()) {
        // have to use a something resource because addModelResource doesn't handle models being upserted/fetched via POST like we're doing here
        if (this.newEarnedAchievements.length) { return this.newEarnedAchievementsResource = this.supermodel.addSomethingResource('earned achievements'); }
      }
    }

    getRenderData() {
      let achievement;
      const c = super.getRenderData();
      // get the gems and xp earned from the achievements
      const earnedAchievementMap = _.indexBy(this.newEarnedAchievements || [], ea => ea.get('achievement'));
      for (achievement of Array.from(((this.achievements != null ? this.achievements.models : undefined) || []))) {
        var earnedAchievement = earnedAchievementMap[achievement.id];
        if (earnedAchievement) {
          achievement.completedAWhileAgo = (new Date().getTime() - Date.parse(earnedAchievement.attributes.changed)) > (30 * 1000);
        }
        achievement.worth = achievement.get('worth', true);
        achievement.gems = __guard__(achievement.get('rewards'), x => x.gems);
      }
      c.achievements = (this.achievements != null ? this.achievements.models.slice() : undefined) || [];
      for (achievement of Array.from(c.achievements)) {
        var left, left1, proportionalTo;
        achievement.description = utils.i18n(achievement.attributes, 'description');
        if (!this.supermodel.finished() || !(proportionalTo = achievement.get('proportionalTo'))) { continue; }
        // For repeatable achievements, we modify their base worth/gems by their repeatable growth functions.
        var achievedAmount = utils.getByPath(this.session.attributes, proportionalTo);
        var previousAmount = Math.max(0, achievedAmount - 1);
        var func = achievement.getExpFunction();
        achievement.previousWorth = ((left = achievement.get('worth')) != null ? left : 0) * func(previousAmount);
        achievement.worth = ((left1 = achievement.get('worth')) != null ? left1 : 0) * func(achievedAmount);
        var rewards = achievement.get('rewards');
        if (rewards != null ? rewards.gems : undefined) { achievement.gems = (rewards != null ? rewards.gems : undefined) * func(achievedAmount); }
        if (rewards != null ? rewards.gems : undefined) { achievement.previousGems = (rewards != null ? rewards.gems : undefined) * func(previousAmount); }
      }

      c.thangTypes = this.thangTypes;
      return c;
    }

    initializeAnimations() {
      if (!this.level.isType('course', 'hero', 'course-ladder', 'game-dev', 'web-dev')) { return this.endSequentialAnimations(); }
      const complete = _.once(_.bind(this.beginSequentialAnimations, this));
      this.animatedPanels = $();
      const panels = this.$el.find('.achievement-panel');
      for (var panel of Array.from(panels)) {
        panel = $(panel);
        if (panel.data('animate') == null) { continue; }
        this.animatedPanels = this.animatedPanels.add(panel);
        panel.queue(function() {
          $(this).addClass('earned'); // animate out the grayscale
          return $(this).dequeue();
        });
        panel.delay(500);
        panel.queue(function() {
          $(this).find('.reward-image-container').addClass('show');
          return $(this).dequeue();
        });
        panel.delay(500);
        panel.queue(() => complete());
      }
      this.animationComplete = !this.animatedPanels.length;
      if (this.animationComplete) { return complete(); }
    }

    beginSequentialAnimations() {
      let panel;
      if (this.destroyed) { return; }
      if (!this.level.isType('course', 'hero', 'course-ladder', 'game-dev', 'web-dev')) { return; }
      this.sequentialAnimatedPanels = _.map(this.animatedPanels.find('.reward-panel'), panel => ({
        number: $(panel).data('number'),
        previousNumber: $(panel).data('previous-number'),
        textEl: $(panel).find('.reward-text'),
        rootEl: $(panel),
        unit: $(panel).data('number-unit'),
        item: $(panel).data('item-thang-type')
      }));

      this.totalXP = 0;
      for (panel of Array.from(this.sequentialAnimatedPanels)) { if (panel.unit === 'xp') { this.totalXP += panel.number; } }
      this.totalGems = 0;
      for (panel of Array.from(this.sequentialAnimatedPanels)) { if (panel.unit === 'gem') { this.totalGems += panel.number; } }
      this.totalXPAnimated = (this.totalGemsAnimated = (this.lastTotalXP = (this.lastTotalGems = 0)));
      this.sequentialAnimationStart = new Date();
      return this.sequentialAnimationInterval = setInterval(this.tickSequentialAnimation, 1000 / 60);
    }

    tickSequentialAnimation() {
      // TODO: make sure the animation pulses happen when the numbers go up and sounds play (up to a max speed)
      let duration, panel;
      if (!(panel = this.sequentialAnimatedPanels[0])) { return this.endSequentialAnimations(); }
      if (panel.number) {
        duration = (Math.log(panel.number + 1) / Math.LN10) * 1000;  // Math.log10 is ES6
      } else {
        duration = 1000;
      }
      const ratio = this.getEaseRatio((new Date() - this.sequentialAnimationStart), duration);
      if (panel.unit === 'xp') {
        const newXP = Math.floor(ratio * (panel.number - panel.previousNumber));
        const totalXP = this.totalXPAnimated + newXP;
        if (totalXP !== this.lastTotalXP) {
          panel.textEl.text('+' + newXP);
          const xpTrigger = 'xp-' + (totalXP % 6);  // 6 xp sounds
          this.playSound(xpTrigger, (0.5 + (ratio / 2)));
          this.lastTotalXP = totalXP;
        }
      } else if (panel.unit === 'gem') {
        const newGems = Math.floor(ratio * (panel.number - panel.previousNumber));
        const totalGems = this.totalGemsAnimated + newGems;
        if (totalGems !== this.lastTotalGems) {
          panel.textEl.text('+' + newGems);
          const gemTrigger = 'gem-' + (parseInt(panel.number * ratio) % 4);  // 4 gem sounds
          this.playSound(gemTrigger, (0.5 + (ratio / 2)));
          this.lastTotalGems = totalGems;
        }
      } else if (panel.item) {
        const thangType = this.thangTypes[panel.item];
        panel.textEl.text(utils.i18n(thangType.attributes, 'name'));
        if (0.5 < ratio && ratio < 0.6) { this.playSound('item-unlocked'); }
      }
      if (ratio === 1) {
        panel.rootEl.removeClass('animating').find('.reward-image-container img').removeClass('pulse');
        this.sequentialAnimationStart = new Date();
        if (panel.unit === 'xp') {
          this.totalXPAnimated += panel.number - panel.previousNumber;
        } else if (panel.unit === 'gem') {
          this.totalGemsAnimated += panel.number - panel.previousNumber;
        }
        this.sequentialAnimatedPanels.shift();
        return;
      }
      return panel.rootEl.addClass('animating').find('.reward-image-container').removeClass('pending-reward-image').find('img').addClass('pulse');
    }

    getEaseRatio(timeSinceStart, duration) {
      // Ease in/out quadratic - http://gizma.com/easing/
      timeSinceStart = Math.min(timeSinceStart, duration);
      let t = (2 * timeSinceStart) / duration;
      if (t < 1) {
        return 0.5 * t * t;
      }
      --t;
      return -0.5 * ((t * (t - 2)) - 1);
    }

    endSequentialAnimations() {
      clearInterval(this.sequentialAnimationInterval);
      this.animationComplete = true;
      return Backbone.Mediator.publish('music-player:enter-menu', {terrain: this.level.get('terrain', true) || 'forest'});
    }
  };
  CourseRewardsView.initClass();
  return CourseRewardsView;
})());
function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}