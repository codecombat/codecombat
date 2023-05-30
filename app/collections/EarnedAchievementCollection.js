// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let EarnedAchievementCollection;
import CocoCollection from 'collections/CocoCollection';
import EarnedAchievement from 'models/EarnedAchievement';

export default EarnedAchievementCollection = (function() {
  EarnedAchievementCollection = class EarnedAchievementCollection extends CocoCollection {
    static initClass() {
      this.prototype.model = EarnedAchievement;
    }

    initialize(userID) {
      this.url = `/db/user/${userID}/achievements`;
      return super.initialize();
    }
  };
  EarnedAchievementCollection.initClass();
  return EarnedAchievementCollection;
})();
