// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const CocoCollection = require('collections/CocoCollection')
const Achievement = require('models/Achievement')

class RelatedAchievementCollection extends CocoCollection {
  static initClass () {
    this.prototype.model = Achievement
  }

  constructor (relatedID) {
    super()
    this.url = `/db/achievement?related=${relatedID}`
  }
}
RelatedAchievementCollection.initClass()

module.exports = RelatedAchievementCollection
