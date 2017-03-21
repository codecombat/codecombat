CocoCollection = require './CocoCollection'
LevelSession = require 'models/LevelSession'

module.exports = class RecentlyPlayedCollection extends CocoCollection
  model: LevelSession

  constructor: (userID, options) ->
    @url = "/db/user/#{userID}/recently_played"
    super options
