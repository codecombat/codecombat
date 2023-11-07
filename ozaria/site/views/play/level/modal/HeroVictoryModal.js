/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS204: Change includes calls to have a more natural evaluation order
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let HeroVictoryModal;
require('app/styles/play/level/modal/hero-victory-modal.sass');
const ModalView = require('views/core/ModalView');
const CreateAccountModal = require('views/core/CreateAccountModal');
const template = require('templates/play/level/modal/hero-victory-modal');
const Achievement = require('models/Achievement');
const EarnedAchievement = require('models/EarnedAchievement');
const CocoCollection = require('collections/CocoCollection');
const LocalMongo = require('lib/LocalMongo');
let utils = require('core/utils');
const ThangType = require('models/ThangType');
const LadderSubmissionView = require('views/play/common/LadderSubmissionView');
const AudioPlayer = require('lib/AudioPlayer');
const User = require('models/User');
utils = require('core/utils');
const Course = require('models/Course');
const Level = require('models/Level');
const LevelFeedback = require('models/LevelFeedback');
const storage = require('core/storage');
const SubscribeModal = require('views/core/SubscribeModal');
const AmazonHocModal = require('views/play/modal/AmazonHocModal');
const forms = require('core/forms');
const contact = require('core/contact');

module.exports = (HeroVictoryModal = (function() {
  HeroVictoryModal = class HeroVictoryModal extends ModalView {
    static initClass() {
      this.prototype.id = 'hero-victory-modal';
      this.prototype.template = template;
      this.prototype.closeButton = false;
      this.prototype.closesOnClickOutside = false;

      this.prototype.subscriptions =
        {'ladder:game-submitted': 'onGameSubmitted'};

      this.prototype.events = {
        'click #continue-button': 'onClickContinue',
        'click .leaderboard-button': 'onClickLeaderboard',
        'click .return-to-course-button': 'onClickReturnToCourse',
        'click .return-to-ladder-button': 'onClickReturnToLadder',
        'click .sign-up-button': 'onClickSignupButton',
        'click .continue-from-offer-button': 'onClickContinueFromOffer',
        'click .skip-offer-button': 'onClickSkipOffer',
        'click #share-level-btn': 'onClickShareLevelButton',
        'click .subscribe-button': 'onSubscribeButtonClicked',
        'click #amazon-hoc-button': 'onClickAmazonHocButton',
        'input #share-game-with-teacher-input': 'onChangeShareGameWithTeacherInput',
        'click #share-game-with-teacher-btn': 'onClickShareGameWithTeacherButton',

        // Feedback events
        'mouseover .rating i'(e) { return this.showStars(this.starNum($(e.target))); },
        'mouseout .rating i'() { return this.showStars(); },
        'click .rating i'(e) {
          this.setStars(this.starNum($(e.target)));
          return this.$el.find('.review, .review-label').show();
        },
        'keypress .review textarea'() { return this.saveReviewEventually(); }
      };
    }

    constructor(options) {
      super(options);
      this.tickSequentialAnimation = this.tickSequentialAnimation.bind(this);
      this.courseID = options.courseID;
      this.courseInstanceID = options.courseInstanceID;

      this.session = options.session;
      this.level = options.level;
      this.thangTypes = {};
      if (this.level.isType('hero', 'hero-ladder', 'course', 'course-ladder', 'game-dev', 'web-dev')) {
        const achievements = new CocoCollection([], {
          url: `/db/achievement?related=${this.session.get('level').original}`,
          model: Achievement
        });
        this.achievements = this.supermodel.loadCollection(achievements, 'achievements').model;
        this.listenToOnce(this.achievements, 'sync', this.onAchievementsLoaded);
        this.readyToContinue = false;
        this.waitingToContinueSince = new Date();
        this.previousXP = me.get('points', true);
        this.previousLevel = me.level();
      } else {
        this.readyToContinue = true;
      }
      this.playSound('victory');
      if (this.level.isType('course', 'course-ladder')) {
        this.saveReviewEventually = _.debounce(this.saveReviewEventually, 2000);
        this.loadExistingFeedback();
      }

      if (this.level.get('shareable') === 'project') {
        this.shareURL = `${window.location.origin}/play/${this.level.get('type')}-level/${this.session.id}`;
      }

      this.trackAwsButtonShown = _.once(() => window.tracker != null ? window.tracker.trackEvent('Show Amazon Modal Button') : undefined);
    }

    destroy() {
      clearInterval(this.sequentialAnimationInterval);
      if (this.$el.find('.review textarea').val()) { this.saveReview(); }
      if (this.feedback != null) {
        this.feedback.off();
      }
      return super.destroy();
    }

    onHidden() {
      Backbone.Mediator.publish('music-player:exit-menu', {});
      return super.onHidden();
    }

    loadExistingFeedback() {
      const url = `/db/level/${this.level.id}/feedback`;
      this.feedback = new LevelFeedback();
      this.feedback.setURL(url);
      this.feedback.fetch({cache: false});
      this.listenToOnce(this.feedback, 'sync', function() { return this.onFeedbackLoaded(); });
      return this.listenToOnce(this.feedback, 'error', function() { return this.onFeedbackNotFound(); });
    }

    onFeedbackLoaded() {
      this.feedback.url = function() { return '/db/level.feedback/' + this.id; };
      this.$el.find('.review textarea').val(this.feedback.get('review'));
      this.$el.find('.review, .review-label').show();
      return this.showStars();
    }

    onFeedbackNotFound() {
      this.feedback = new LevelFeedback();
      this.feedback.set('levelID', this.level.get('slug') || this.level.id);
      this.feedback.set('levelName', this.level.get('name') || '');
      this.feedback.set('level', {majorVersion: this.level.get('version').major, original: this.level.get('original')});
      return this.showStars();
    }

    onAchievementsLoaded() {
      let achievement;
      this.achievements.models = _.filter(this.achievements.models, m => !__guard__(m.get('query'), x => x.ladderAchievementDifficulty));  // Don't show higher AI difficulty achievements
      this.$el.toggleClass('full-achievements', this.achievements.models.length === 3);
      let thangTypeOriginals = [];
      const achievementIDs = [];
      for (achievement of Array.from(this.achievements.models)) {
        var rewards = achievement.get('rewards') || {};
        thangTypeOriginals.push(rewards.heroes || []);
        thangTypeOriginals.push(rewards.items || []);
        achievement.completed = LocalMongo.matchesQuery(this.session.attributes, achievement.get('query'));
        if (achievement.completed) { achievementIDs.push(achievement.id); }
      }

      thangTypeOriginals = _.uniq(_.flatten(thangTypeOriginals));
      for (var thangTypeOriginal of Array.from(thangTypeOriginals)) {
        var thangType = new ThangType();
        thangType.url = `/db/thang.type/${thangTypeOriginal}/version`;
        //thangType.project = ['original', 'rasterIcon', 'name', 'soundTriggers', 'i18n']  # This is what we need, but the PlayHeroesModal needs more, and so we load more to fill up the supermodel.
        thangType.project = ['original', 'rasterIcon', 'name', 'slug', 'soundTriggers', 'featureImages', 'gems', 'heroClass', 'description', 'components', 'extendedName', 'shortName', 'unlockLevelName', 'i18n', 'subscriber'];
        this.thangTypes[thangTypeOriginal] = this.supermodel.loadModel(thangType).model;
      }

      this.newEarnedAchievements = [];
      let hadOneCompleted = false;
      for (achievement of Array.from(this.achievements.models)) {
        if (!achievement.completed) { continue; }
        hadOneCompleted = true;
        var ea = new EarnedAchievement({
          collection: achievement.get('collection'),
          triggeredBy: this.session.id,
          achievement: achievement.id
        });
        ea.save();
        this.newEarnedAchievements.push(ea);
        this.listenToOnce(ea, 'sync', function() {
          if (_.all(((() => {
            const result = [];
            for (ea of Array.from(this.newEarnedAchievements)) {               result.push(ea.id);
            }
            return result;
          })()))) {
            this.newEarnedAchievementsResource.markLoaded();
            this.listenToOnce(me, 'sync', function() {
              this.readyToContinue = true;
              return this.updateSavingProgressStatus();
            });
            if (!me.loading) { return me.fetch({cache: false}); }
          }
        });
      }

      if (!hadOneCompleted) { this.readyToContinue = true; }

      // have to use a something resource because addModelResource doesn't handle models being upserted/fetched via POST like we're doing here
      if (this.newEarnedAchievements.length) { return this.newEarnedAchievementsResource = this.supermodel.addSomethingResource('earned achievements'); }
    }

    getRenderData() {
      let achievement;
      const c = super.getRenderData();
      c.levelName = utils.i18n(this.level.attributes, 'name');
      if (this.level.isType('hero', 'game-dev', 'web-dev')) {
        let left;
        c.victoryText = utils.i18n((left = this.level.get('victory')) != null ? left : {}, 'body');
      }
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
        var left1, left2, proportionalTo;
        achievement.description = utils.i18n(achievement.attributes, 'description');
        if (!this.supermodel.finished() || !(proportionalTo = achievement.get('proportionalTo'))) { continue; }
        // For repeatable achievements, we modify their base worth/gems by their repeatable growth functions.
        var achievedAmount = utils.getByPath(this.session.attributes, proportionalTo);
        var previousAmount = Math.max(0, achievedAmount - 1);
        var func = achievement.getExpFunction();
        achievement.previousWorth = ((left1 = achievement.get('worth')) != null ? left1 : 0) * func(previousAmount);
        achievement.worth = ((left2 = achievement.get('worth')) != null ? left2 : 0) * func(achievedAmount);
        var rewards = achievement.get('rewards');
        if (rewards != null ? rewards.gems : undefined) { achievement.gems = (rewards != null ? rewards.gems : undefined) * func(achievedAmount); }
        if (rewards != null ? rewards.gems : undefined) { achievement.previousGems = (rewards != null ? rewards.gems : undefined) * func(previousAmount); }
      }

      // for testing the three states
      //if c.achievements.length
      //  c.achievements = [c.achievements[0].clone(), c.achievements[0].clone(), c.achievements[0].clone()]
      //for achievement, index in c.achievements
      //#  achievement.completed = index > 0
      //#  achievement.completedAWhileAgo = index > 1
      //  achievement.completed = true
      //  achievement.completedAWhileAgo = false
      //  achievement.attributes.worth = (index + 1) * achievement.get('worth', true)
      //  rewards = achievement.get('rewards') or {}
      //  rewards.gems *= (index + 1)

      c.thangTypes = this.thangTypes;
      c.me = me;
      c.readyToRank = this.level.isType('hero-ladder', 'course-ladder') && this.session.readyToRank();
      c.level = this.level;
      c.i18n = utils.i18n;

      const elapsed = (new Date() - new Date(me.get('dateCreated')));
      if (me.get('hourOfCode')) {
        // Show the Hour of Code "I'm Done" tracking pixel after they played for 20 minutes
        const gameDevHoc = application.getHocCampaign();
        const lastLevelOriginal = (() => { switch (gameDevHoc) {
          case 'game-dev-hoc': return '57ee6f5786cf4e1f00afca2c'; // game grove
          case 'game-dev-hoc-2': return '57b71dce7a14ff35003a8f71'; // palimpsest
          default: return '541c9a30c6362edfb0f34479'; // kithgard gates for dungeon
        } })();
        const lastLevel = this.level.get('original') === lastLevelOriginal;
        const enough = (elapsed >= (20 * 60 * 1000)) || lastLevel;
        const tooMuch = elapsed > (120 * 60 * 1000);
        const showDone = ((elapsed >= (30 * 60 * 1000)) && !tooMuch) || lastLevel;
        if (enough && !tooMuch && !me.get('hourOfCodeComplete')) {
          const pixelCode = (() => { switch (gameDevHoc) {
            case 'game-dev-hoc': return 'code_combat_gamedev';
            case 'game-dev-hoc-2': return 'code_combat_build_arcade';
            case 'ai-league-hoc': return 'codecombat_esports';
            case 'goblins-hoc': return 'codecombat_goblins';
            default: return 'code_combat';
          } })();
          $('body').append($(`<img src='https://code.org/api/hour/finish_${pixelCode}.png' style='visibility: hidden;'>`));
          me.set('hourOfCodeComplete', true);
          me.patch();
          if (window.tracker != null) {
            window.tracker.trackEvent('Hour of Code Finish');
          }
        }
        // Show the "I'm done" button between 30 - 120 minutes if they definitely came from Hour of Code
        c.showHourOfCodeDoneButton = showDone;
        this.showAmazonHocButton = (gameDevHoc === 'game-dev-hoc') && lastLevel;
        if (this.showAmazonHocButton) {
          this.trackAwsButtonShown();
        }
        this.showHoc2016ExploreButton = gameDevHoc && lastLevel;
        this.showShareGameWithTeacher = gameDevHoc && lastLevel;
      }

      c.showLeaderboard = (__guard__(this.level.get('scoreTypes'), x1 => x1.length) > 0) && !this.level.isType('course') && !this.showAmazonHocButton && !this.showHoc2016ExploreButton;

      c.showReturnToCourse = !c.showLeaderboard && !me.get('anonymous') && this.level.isType('course', 'course-ladder');
      c.isCourseLevel = this.level.isType('course');
      c.currentCourseName = this.course != null ? this.course.get('name') : undefined;
      c.currentLevelName = this.level != null ? this.level.get('name') : undefined;
      c.nextLevelName = this.nextLevel != null ? this.nextLevel.get('name') : undefined;

      return c;
    }

    afterRender() {
      super.afterRender();
      this.$el.toggleClass('with-achievements', this.level.isType('hero', 'hero-ladder', 'game-dev', 'web-dev'));
      if (!this.supermodel.finished()) { return; }
      for (var original in this.thangTypes) { var hero = this.thangTypes[original]; this.playSelectionSound(hero, true); }  // Preload them
      this.updateSavingProgressStatus();
      this.initializeAnimations();
      if (this.level.isType('hero-ladder', 'course-ladder')) {
        this.ladderSubmissionView = new LadderSubmissionView({session: this.session, level: this.level});
        return this.insertSubView(this.ladderSubmissionView, this.$el.find('.ladder-submission-view'));
      }
    }

    initializeAnimations() {
      if (!this.level.isType('hero', 'hero-ladder', 'game-dev', 'web-dev')) { return this.endSequentialAnimations(); }
      this.updateXPBars(0);
      //playVictorySound = => @playSound 'victory-title-appear'  # TODO: actually add this
      this.$el.find('#victory-header').delay(250).queue(function() {
        return $(this).removeClass('out').dequeue();
        //playVictorySound()
      });
      const complete = _.once(_.bind(this.beginSequentialAnimations, this));
      this.animatedPanels = $();
      const panels = this.$el.find('.achievement-panel');
      for (var panel of Array.from(panels)) {
        panel = $(panel);
        if (panel.data('animate') == null) { continue; }
        this.animatedPanels = this.animatedPanels.add(panel);
        panel.delay(500);  // Waiting for victory header to show up and fall
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
      if (!this.level.isType('hero', 'hero-ladder', 'game-dev', 'web-dev')) { return; }
      this.sequentialAnimatedPanels = _.map(this.animatedPanels.find('.reward-panel'), panel => ({
        number: $(panel).data('number'),
        previousNumber: $(panel).data('previous-number'),
        textEl: $(panel).find('.reward-text'),
        rootEl: $(panel),
        unit: $(panel).data('number-unit'),
        hero: $(panel).data('hero-thang-type'),
        item: $(panel).data('item-thang-type')
      }));

      this.totalXP = 0;
      for (panel of Array.from(this.sequentialAnimatedPanels)) { if (panel.unit === 'xp') { this.totalXP += panel.number; } }
      this.totalGems = 0;
      for (panel of Array.from(this.sequentialAnimatedPanels)) { if (panel.unit === 'gem') { this.totalGems += panel.number; } }
      this.gemEl = $('#gem-total');
      this.XPEl = $('#xp-total');
      this.totalXPAnimated = (this.totalGemsAnimated = (this.lastTotalXP = (this.lastTotalGems = 0)));
      this.sequentialAnimationStart = new Date();
      return this.sequentialAnimationInterval = setInterval(this.tickSequentialAnimation, 1000 / 60);
    }

    tickSequentialAnimation() {
      // TODO: make sure the animation pulses happen when the numbers go up and sounds play (up to a max speed)
      let duration, panel, thangType;
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
          this.XPEl.text(totalXP);
          this.updateXPBars(totalXP);
          const xpTrigger = 'xp-' + (totalXP % 6);  // 6 xp sounds
          this.playSound(xpTrigger, (0.5 + (ratio / 2)));
          if ((totalXP >= 1000) && (this.lastTotalXP < 1000)) { this.XPEl.addClass('four-digits'); }
          if ((totalXP >= 10000) && (this.lastTotalXP < 10000)) { this.XPEl.addClass('five-digits'); }
          this.lastTotalXP = totalXP;
        }
      } else if (panel.unit === 'gem') {
        const newGems = Math.floor(ratio * (panel.number - panel.previousNumber));
        const totalGems = this.totalGemsAnimated + newGems;
        if (totalGems !== this.lastTotalGems) {
          panel.textEl.text('+' + newGems);
          this.gemEl.text(totalGems);
          const gemTrigger = 'gem-' + (parseInt(panel.number * ratio) % 4);  // 4 gem sounds
          this.playSound(gemTrigger, (0.5 + (ratio / 2)));
          if ((totalGems >= 1000) && (this.lastTotalGems < 1000)) { this.gemEl.addClass('four-digits'); }
          if ((totalGems >= 10000) && (this.lastTotalGems < 10000)) { this.gemEl.addClass('five-digits'); }
          this.lastTotalGems = totalGems;
        }
      } else if (panel.item) {
        thangType = this.thangTypes[panel.item];
        panel.textEl.text(utils.i18n(thangType.attributes, 'name'));
        if (0.5 < ratio && ratio < 0.6) { this.playSound('item-unlocked'); }
      } else if (panel.hero) {
        thangType = this.thangTypes[panel.hero];
        panel.textEl.text(utils.i18n(thangType.attributes, 'name'));
        if (0.5 < ratio && ratio < 0.6) { this.playSelectionSound(thangType); }
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

    updateXPBars(achievedXP) {
      let newlyAchievedPercentage;
      let {
        previousXP
      } = this;
      if (me.isInGodMode()) { previousXP = previousXP + 1000000; }
      const {
        previousLevel
      } = this;

      const currentXP = previousXP + achievedXP;
      const currentLevel = User.levelFromExp(currentXP);
      const currentLevelXP = User.expForLevel(currentLevel);

      const nextLevel = currentLevel + 1;
      const nextLevelXP = User.expForLevel(nextLevel);

      const leveledUp = currentLevel > previousLevel;
      const totalXPNeeded = nextLevelXP - currentLevelXP;
      let alreadyAchievedPercentage = (100 * (previousXP - currentLevelXP)) / totalXPNeeded;
      if (alreadyAchievedPercentage < 0) { alreadyAchievedPercentage = 0; }  // In case of level up
      if (leveledUp) {
        newlyAchievedPercentage = (100 * (currentXP - currentLevelXP)) / totalXPNeeded;
      } else {
        newlyAchievedPercentage = (100 * achievedXP) / totalXPNeeded;
      }

      const xpEl = $('#xp-wrapper');
      const xpBarJustEarned = xpEl.find('.xp-bar-already-achieved').css('width', alreadyAchievedPercentage + '%');
      const xpBarTotal = xpEl.find('.xp-bar-total').css('width', (alreadyAchievedPercentage + newlyAchievedPercentage) + '%');
      const levelLabel = xpEl.find('.level');
      utils.replaceText(levelLabel, currentLevel);

      if (leveledUp && (!this.displayedLevel || (currentLevel > this.displayedLevel))) {
        this.playSound('level-up');
      }
      return this.displayedLevel = currentLevel;
    }

    endSequentialAnimations() {
      clearInterval(this.sequentialAnimationInterval);
      this.animationComplete = true;
      this.updateSavingProgressStatus();
      return Backbone.Mediator.publish('music-player:enter-menu', {terrain: this.level.get('terrain', true) || 'forest'});
    }

    updateSavingProgressStatus() {
      this.$el.find('#saving-progress-label').toggleClass('hide', this.readyToContinue);
      this.$el.find('.next-level-button').toggleClass('hide', !this.readyToContinue);
      return this.$el.find('.sign-up-poke').toggleClass('hide', !this.readyToContinue);
    }

    onGameSubmitted(e) {
      return this.returnToLadder();
    }

    returnToLadder() {
      // Preserve the supermodel as we navigate back to the ladder.
      let leagueID;
      const viewArgs = [{supermodel: this.options.hasReceivedMemoryWarning ? null : this.supermodel}, this.level.get('slug')];
      let ladderURL = `/play/ladder/${this.level.get('slug') || this.level.id}`;
      if (leagueID = (this.courseInstanceID || utils.getQueryVariable('league'))) {
        const leagueType = this.level.isType('course-ladder') ? 'course' : 'clan';
        viewArgs.push(leagueType);
        viewArgs.push(leagueID);
        ladderURL += `/${leagueType}/${leagueID}`;
      }
      ladderURL += '#my-matches';
      this.hide();
      return Backbone.Mediator.publish('router:navigate', {route: ladderURL, viewClass: 'views/ladder/LadderView', viewArgs});
    }

    playSelectionSound(hero, preload) {
      let sound, sounds;
      if (preload == null) { preload = false; }
      if (!(sounds = __guard__(hero.get('soundTriggers'), x => x.selected))) { return; }
      if (!(sound = sounds[Math.floor(Math.random() * sounds.length)])) { return; }
      const name = AudioPlayer.nameForSoundReference(sound);
      if (preload) {
        return AudioPlayer.preloadSoundReference(sound);
      } else {
        return AudioPlayer.playSound(name, 1);
      }
    }

    getNextLevelCampaign() {
      let needle;
      let campaign = this.level.get('campaign');
      if ((needle = this.level.get('slug'), Array.from(campaignEndLevels).includes(needle))) {
        campaign = '';  // Return to campaign selector
      }
      const gdHocLevels = ['kithgard-gates', 'over-the-garden-wall', 'vorpal-mouse', 'forest-incursion', 'them-bones', 'behavior-driven-development', 'seeing-is-believing', 'persistence-pays', 'game-grove'];
      if (application.getHocCampaign()) {
        // Return to game-dev-hoc instead if we're in that mode, since the levels don't realize they can be in that copycat campaign
        campaign = application.getHocCampaign();
      }
      return campaign;
    }

    getNextLevelLink(returnToCourse) {
      let link;
      if (returnToCourse == null) { returnToCourse = false; }
      if (this.level.isType('course')) {
        link = "/students";
        if (this.courseID) {
          link += `/${this.courseID}`;
          if (this.courseInstanceID) { link += `/${this.courseInstanceID}`; }
        }
      } else {
        link = '/play';
        const nextCampaign = this.getNextLevelCampaign();
        link += '/' + nextCampaign;
      }
      return link;
    }

    onClickContinue(e, extraOptions=null) {
      let needle1, viewArgs, viewClass;
      this.playSound('menu-button-click');
      let nextLevelLink = this.getNextLevelLink(extraOptions != null ? extraOptions.returnToCourse : undefined);
      // Preserve the supermodel as we navigate back to the world map.
      const options = {
        justBeatLevel: this.level,
        supermodel: this.options.hasReceivedMemoryWarning ? null : this.supermodel
      };
      if (extraOptions) { _.merge(options, extraOptions); }
      if (this.showHoc2016ExploreButton) {
        // Send players to /play after completing final game-dev activity project level
        nextLevelLink = '/play';
        viewClass = 'views/play/CampaignView';
        viewArgs = [options];
      } else if (this.level.isType('course') && this.nextLevel && !options.returnToCourse) {
        viewClass = 'views/play/level/PlayLevelView';
        options.courseID = this.courseID;
        options.courseInstanceID = this.courseInstanceID;
        viewArgs = [options, this.nextLevel.get('slug')];
      } else if (this.level.isType('course')) {
        // TODO: shouldn't set viewClass and route in different places
        viewClass = 'views/courses/CoursesView';
        viewArgs = [options];
        if (this.courseID) {
          viewClass = 'views/courses/CourseDetailsView';
          viewArgs.push(this.courseID);
          if (this.courseInstanceID) { viewArgs.push(this.courseInstanceID); }
        }
      } else if (this.level.isType('course-ladder')) {
        const leagueID = this.courseInstanceID || utils.getQueryVariable('league');
        nextLevelLink = `/play/ladder/${this.level.get('slug')}`;
        if (leagueID) { nextLevelLink += `/course/${leagueID}`; }
        viewClass = 'views/ladder/LadderView';
        viewArgs = [options, this.level.get('slug')];
        if (leagueID) { viewArgs = viewArgs.concat(['course', leagueID]); }
      } else {
        let needle;
        if ((needle = this.level.get('slug'), Array.from(campaignEndLevels).includes(needle))) {
          options.worldComplete = this.level.get('campaign') || true;
        }
        viewClass = 'views/play/CampaignView';
        viewArgs = [options, this.getNextLevelCampaign()];
      }
      const navigationEvent = {route: nextLevelLink, viewClass, viewArgs};
      if ((this.level.get('slug') === 'lost-viking') && !((needle1 = me.get('age'), ['0-13', '14-17'].includes(needle1)))) {
        return this.showOffer(navigationEvent);
      } else {
        this.hide();
        return Backbone.Mediator.publish('router:navigate', navigationEvent);
      }
    }

    onClickLeaderboard(e) {
      return this.onClickContinue(e, {showLeaderboard: true});
    }

    onClickReturnToCourse(e) {
      return this.onClickContinue(e, {returnToCourse: true});
    }

    onClickReturnToLadder(e) {
      this.playSound('menu-button-click');
      e.preventDefault();
      return this.returnToLadder();
    }

    onClickSignupButton(e) {
      e.preventDefault();
      if (window.tracker != null) {
        window.tracker.trackEvent('Started Signup', {category: 'Play Level', label: 'Hero Victory Modal', level: this.level.get('slug')});
      }
      return this.openModalView(new CreateAccountModal());
    }

    showOffer(navigationEventUponCompletion) {
      this.navigationEventUponCompletion = navigationEventUponCompletion;
      this.$el.find('.modal-footer > *').hide();
      return this.$el.find(`.modal-footer > .offer.${this.level.get('slug')}`).show();
    }

    onClickContinueFromOffer(e) {
      const url = {
        'lost-viking': 'http://www.vikingcodeschool.com/codecombat?utm_source=codecombat&utm_medium=viking_level&utm_campaign=affiliate&ref=Code+Combat+Elite'
      }[this.level.get('slug')];
      this.hide();
      Backbone.Mediator.publish('router:navigate', this.navigationEventUponCompletion);
      if (url) { return window.open(url, '_blank'); }
    }

    onClickSkipOffer(e) {
      this.hide();
      return Backbone.Mediator.publish('router:navigate', this.navigationEventUponCompletion);
    }

    onClickShareLevelButton() {
      this.$('#share-level-input').val(this.shareURL).select();
      return this.tryCopy();
    }

    onClickAmazonHocButton() {
      if (window.tracker != null) {
        window.tracker.trackEvent('Click Amazon Modal Button');
      }
      return this.openModalView(new AmazonHocModal());
    }

    onSubscribeButtonClicked() {
      return this.openModalView(new SubscribeModal());
    }

    onChangeShareGameWithTeacherInput(e) {
      const email = _.string.trim(this.$('#share-game-with-teacher-input').val());
      const valid = forms.validateEmail(email) && !/codecombat/i.test(email);
      return this.$('#share-game-with-teacher-btn').attr('disabled', !valid).text($.i18n.t('common.send'));
    }

    onClickShareGameWithTeacherButton(e) {
      const email = _.string.trim(this.$('#share-game-with-teacher-input').attr('disabled', true).val());
      this.$('#share-game-with-teacher-btn').attr('disabled', true).text($.i18n.t('common.sending'));
      return contact.sendTeacherGameDevProjectShare({teacherEmail: email, sessionId: this.session.id, codeLanguage: this.session.get('codeLanguage') || 'python', levelName: utils.i18n(this.level.attributes, 'name')})
        .then(() => {
          return this.$('#share-game-with-teacher-btn').text($.i18n.t('common.sent'));
      }).catch(() => {
          this.$('#share-game-with-teacher-input').attr('disabled', false).focus();
          return this.$('#share-game-with-teacher-btn').text($.i18n.t('loading_error.error'));
      });
    }

    // Ratings and reviews

    starNum(starEl) { return starEl.prevAll('i').length + 1; }

    showStars(num) {
      this.$el.find('.rating').show();
      if (num == null) { num = (this.feedback != null ? this.feedback.get('rating') : undefined) || 0; }
      const stars = this.$el.find('.rating i');
      stars.removeClass('glyphicon-star').addClass('glyphicon-star-empty');
      return stars.slice(0, num).removeClass('glyphicon-star-empty').addClass('glyphicon-star');
    }

    setStars(num) {
      this.feedback.set('rating', num);
      return this.feedback.save();
    }

    saveReviewEventually() {
      return this.saveReview();
    }

    saveReview() {
      this.feedback.set('review', this.$el.find('.review textarea').val());
      return this.feedback.save();
    }
  };
  HeroVictoryModal.initClass();
  return HeroVictoryModal;
})());


// Much easier to just keep this updated than to dynamically figure it out.
var campaignEndLevels = [
  'kithgard-gates',
  'kithgard-mastery',
  'tabula-rasa',
  'wanted-poster',
  'siege-of-stonehold',
  'go-fetch',
  'palimpsest',
  'quizlet',
  'clash-of-clones',
  'summits-gate'
];

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}