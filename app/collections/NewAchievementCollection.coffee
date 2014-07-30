CocoCollection = require 'collections/CocoCollection'
Achievement = require 'models/Achievement'

class NewAchievementCollection extends CocoCollection
  model: Achievement

  initialize: (me = require('lib/auth').me) ->
    @url = "/db/user/#{me.id}/achievements?notified=false"

module.exports = NewAchievementCollection
