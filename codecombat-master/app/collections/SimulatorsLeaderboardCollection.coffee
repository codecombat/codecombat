CocoCollection = require 'collections/CocoCollection'
User = require 'models/User'

module.exports = class SimulatorsLeaderboardCollection extends CocoCollection
  url: ''
  model: User

  constructor: (options) ->
    super()
    options ?= {}
    @url = "/db/user/me/simulatorLeaderboard?#{$.param(options)}"
