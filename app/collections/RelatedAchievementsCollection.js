// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
import CocoCollection from 'collections/CocoCollection';

import Achievement from 'models/Achievement';

class RelatedAchievementCollection extends CocoCollection {
  static initClass() {
    this.prototype.model = Achievement;
  }

  initialize(relatedID) {
    return this.url = `/db/achievement?related=${relatedID}`;
  }
}
RelatedAchievementCollection.initClass();

export default RelatedAchievementCollection;
