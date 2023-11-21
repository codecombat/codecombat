// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let AchievementPopup;
require('app/styles/achievements.sass');
const CocoView = require('views/core/CocoView');
const template = require('app/templates/core/achievement-popup');
const User = require('../../models/User');
const Achievement = require('../../models/Achievement');

module.exports = (AchievementPopup = (function() {
  AchievementPopup = class AchievementPopup extends CocoView {
    static initClass() {
      this.prototype.className = 'achievement-popup';
      this.prototype.template = template;
    }

    constructor(options) {
      super(options);
      this.achievement = options.achievement;
      this.earnedAchievement = options.earnedAchievement;
      this.container = options.container || this.getContainer();
      this.popup = options.container;
      if (this.popup == null) { this.popup = true; }
      if (this.popup) { this.className += ' popup'; }
      this.render();
    }

    calculateData() {
      let achievedXP, data;
      const currentLevel = me.level();
      const nextLevel = currentLevel + 1;
      const currentLevelXP = User.expForLevel(currentLevel);
      const nextLevelXP = User.expForLevel(nextLevel);
      const totalXPNeeded = nextLevelXP - currentLevelXP;
      const expFunction = this.achievement.getExpFunction();
      const currentXP = me.get('points', true);
      if (this.achievement.isRepeatable()) {
        if (this.achievement.isRepeatable()) { achievedXP = expFunction(this.earnedAchievement.get('previouslyAchievedAmount')) * this.achievement.get('worth'); }
      } else {
        achievedXP = this.achievement.get('worth', true);
      }
      const previousXP = currentXP - achievedXP;
      const leveledUp = (currentXP - achievedXP) < currentLevelXP;
      //console.debug 'Leveled up' if leveledUp
      let alreadyAchievedPercentage = (100 * (previousXP - currentLevelXP)) / totalXPNeeded;
      if (alreadyAchievedPercentage < 0) { alreadyAchievedPercentage = 0; } // In case of level up
      const newlyAchievedPercentage = leveledUp ? (100 * (currentXP - currentLevelXP)) / totalXPNeeded :  (100 * achievedXP) / totalXPNeeded;

      //console.debug "Current level is #{currentLevel} (#{currentLevelXP} xp), next level is #{nextLevel} (#{nextLevelXP} xp)."
      //console.debug "Need a total of #{nextLevelXP - currentLevelXP}, already had #{previousXP} and just now earned #{achievedXP} totalling on #{currentXP}"

      return data = {
        title: this.achievement.i18nName(),
        imgURL: this.achievement.getImageURL(),
        description: this.achievement.i18nDescription(),
        level: currentLevel,
        currentXP,
        newXP: achievedXP,
        leftXP: nextLevelXP - currentXP,
        oldXPWidth: alreadyAchievedPercentage,
        newXPWidth: newlyAchievedPercentage,
        leftXPWidth: 100 - newlyAchievedPercentage - alreadyAchievedPercentage
      };
    }

    getRenderData() {
      const c = super.getRenderData();
      _.extend(c, this.calculateData());
      c.style = this.achievement.getStyle();
      c.popup = true;
      c.$ = $; // Allows the jade template to do i18n
      return c;
    }

    render() {
      super.render();
      this.container.prepend(this.$el);
      if (this.popup) {
        const hide = () => {
          if (this.destroyed) { return; }
          return this.$el.animate({left: -600}, () => {
            this.$el.remove();
            return this.destroy();
          });
        };
        this.$el.animate({left: 0});
        this.$el.on('click', hide);
        if (!$('#editor-achievement-edit-view').length) { return _.delay(hide, 10000); }
      }
    }

    getContainer() {
      if (!this.container) {
        this.container = $('.achievement-popup-container');
        if (!this.container.length) {
          $('body').append('<div class="achievement-popup-container"></div>');
          this.container = $('.achievement-popup-container');
        }
      }
      return this.container;
    }

    afterRender() {
      super.afterRender();
      return _.delay(this.initializeTooltips, 1000); // TODO this could be smoother
    }

    initializeTooltips() {
      return $('.progress-bar').addClass('has-tooltip').tooltip();
    }
  };
  AchievementPopup.initClass();
  return AchievementPopup;
})());
