CocoCollection = require 'collections/CocoCollection'

class NewAchievementCollection extends CocoCollection
  initialize: (me = require('lib/auth').me) ->
    @url = "/db/user/#{me.id}/achievements?notified=false"

module.exports = NewAchievementCollection
