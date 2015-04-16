CocoCollection = require 'collections/CocoCollection'
LevelSession = require 'models/LevelSession'

module.exports = class LeaderboardCollection extends CocoCollection
  url: ''
  model: LevelSession

  constructor: (level, options) ->
    super()
    options ?= {}
    @url = "/db/level/#{level.get('original')}.#{level.get('version').major}/leaderboard?#{$.param(options)}"
