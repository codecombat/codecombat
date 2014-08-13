CocoCollection = require 'collections/CocoCollection'
Achievement = require 'models/Achievement'

class RelatedAchievementCollection extends CocoCollection
  model: Achievement

  initialize: (relatedID) ->
    @url = "/db/achievement?related=#{relatedID}"

module.exports = RelatedAchievementCollection
