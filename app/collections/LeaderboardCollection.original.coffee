CocoCollection = require 'collections/CocoCollection'
LevelSession = require 'models/LevelSession'

module.exports = class LeaderboardCollection extends CocoCollection
  url: ''
  model: LevelSession

  constructor: (level, options) ->
    super()
    options ?= {}
    @url = "/db/level/#{level.get('original')}/rankings?#{$.param(options)}"
