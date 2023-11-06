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
let PlayAchievementsModal;
require('app/styles/play/modal/play-achievements-modal.sass');
const ModalView = require('views/core/ModalView');
const template = require('app/templates/play/modal/play-achievements-modal');
const CocoCollection = require('collections/CocoCollection');
const Achievement = require('models/Achievement');
const EarnedAchievement = require('models/EarnedAchievement');

const utils = require('core/utils');

const PAGE_SIZE = 200;

module.exports = (PlayAchievementsModal = (function() {
  PlayAchievementsModal = class PlayAchievementsModal extends ModalView {
    static initClass() {
      this.prototype.className = 'modal fade play-modal';
      this.prototype.template = template;
      this.prototype.id = 'play-achievements-modal';
      this.prototype.plain = true;

      this.prototype.earnedMap = {};
    }

    constructor(options) {
      super(options);
      this.onEverythingLoaded = this.onEverythingLoaded.bind(this);
      this.achievements = new Backbone.Collection();
      const earnedMap = {};

      const achievementsFetcher = new CocoCollection([], {url: '/db/achievement', model: Achievement});
      achievementsFetcher.setProjection([
        'name',
        'description',
        'icon',
        'worth',
        'i18n',
        'rewards',
        'collection',
        'function',
        'query'
      ]);

      const earnedAchievementsFetcher = new CocoCollection([], {url: '/db/earned_achievement', model: EarnedAchievement});
      earnedAchievementsFetcher.setProjection(['achievement', 'achievedAmount']);

      achievementsFetcher.skip = 0;
      achievementsFetcher.fetch({cache: false, data: {skip: 0, limit: PAGE_SIZE}});
      earnedAchievementsFetcher.skip = 0;
      earnedAchievementsFetcher.fetch({cache: false, data: {skip: 0, limit: PAGE_SIZE}});

      this.listenTo(achievementsFetcher, 'sync', this.onAchievementsLoaded);
      this.listenTo(earnedAchievementsFetcher, 'sync', this.onEarnedAchievementsLoaded);
      this.stopListening(this.supermodel, 'loaded-all');

      this.supermodel.loadCollection(achievementsFetcher, 'achievement');
      this.supermodel.loadCollection(earnedAchievementsFetcher, 'achievement');

      this.onEverythingLoaded = _.after(2, this.onEverythingLoaded);
    }

    onAchievementsLoaded(fetcher) {
      const needMore = fetcher.models.length === PAGE_SIZE;
      this.achievements.add(fetcher.models);
      if (needMore) {
        fetcher.skip += PAGE_SIZE;
        return fetcher.fetch({cache: false, data: {skip: fetcher.skip, limit: PAGE_SIZE}});
      } else {
        this.stopListening(fetcher);
        return this.onEverythingLoaded();
      }
    }

    onEarnedAchievementsLoaded(fetcher) {
      const needMore = fetcher.models.length === PAGE_SIZE;
      for (var earned of Array.from(fetcher.models)) {
        this.earnedMap[earned.get('achievement')] = earned;
      }
      if (needMore) {
        fetcher.skip += PAGE_SIZE;
        return fetcher.fetch({cache: false, data: {skip: fetcher.skip, limit: PAGE_SIZE}});
      } else {
        this.stopListening(fetcher);
        return this.onEverythingLoaded();
      }
    }

    onEverythingLoaded() {
      let achievement, earned;
      this.achievements.set(this.achievements.filter(m => (m.get('collection') !== 'level.sessions') || __guard__(m.get('query'), x => x.team)));
      const achievementsByDescription = {earned: {}, unearned: {}};
      for (achievement of Array.from(this.achievements.models)) {
        if (earned = this.earnedMap[achievement.id]) {
          achievement.earned = earned;
          achievement.earnedDate = earned.getCreationDate();
          var expFunction = achievement.getExpFunction();
          achievement.earnedGems = Math.round((__guard__(achievement.get('rewards'), x => x.gems) || 0) * expFunction(earned.get('achievedAmount')));
          achievement.earnedPoints = Math.round((achievement.get('worth', true) || 0) * expFunction(earned.get('achievedAmount')));
        }
        if (achievement.earnedDate == null) { achievement.earnedDate = ''; }
      }
      for (achievement of Array.from(this.achievements.models)) {
        var holder, left, shouldKeep;
        if (achievement.earned) {
          holder = achievementsByDescription.earned;
        } else {
          holder = achievementsByDescription.unearned;
        }
        var nextInSet = holder[achievement.get('description')];
        var [a, b] = Array.from([achievement.get('worth', true), (left = (nextInSet != null ? nextInSet.get('worth', true) : undefined)) != null ? left : 0]);
        if (achievement.earned) {
          shouldKeep = !nextInSet || (a > b);
        } else {
          shouldKeep = !nextInSet || (a < b);
        }
        if (shouldKeep) {
          holder[achievement.get('description')] = achievement;
        }
      }
      this.achievements.set(_.values(achievementsByDescription.earned).concat(_.values(achievementsByDescription.unearned)));
      this.achievements.comparator = m => m.earnedDate;
      this.achievements.sort();
      this.achievements.set(this.achievements.models.reverse());
      for (achievement of Array.from(this.achievements.models)) {
        achievement.name = utils.i18n(achievement.attributes, 'name');
        achievement.description = utils.i18n(achievement.attributes, 'description');
      }
      return this.render();
    }

    afterRender() {
      super.afterRender();
      if (!this.supermodel.finished()) { return; }
      return this.playSound('game-menu-open');
    }

    onHidden() {
      super.onHidden();
      return this.playSound('game-menu-close');
    }
  };
  PlayAchievementsModal.initClass();
  return PlayAchievementsModal;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}