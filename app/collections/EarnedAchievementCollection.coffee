CocoCollection = require 'collections/CocoCollection'

module.exports = class EarnedAchievementCollection extends CocoCollection

  initialize: (me = require('lib/auth').me) ->
    @url = "/db/user/#{me.id}/achievements"

