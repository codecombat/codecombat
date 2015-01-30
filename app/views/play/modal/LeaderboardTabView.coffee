CocoView = require 'views/core/CocoView'
template = require 'templates/play/modal/leaderboard-tab-view'

module.exports = class LeaderboardTabView extends CocoView
  template: template
  className: 'leaderboard-tab-view'
  helpVideoHeight: '295'
  helpVideoWidth: '471'

  events:
    'click .start-subscription-button': "clickSubscribe"

  constructor: (options) ->
    super options
    @timespan = @options.timespan
    @levelOriginal = @options.levelOriginal

  destroy: ->
    super()

  getRenderData: ->
    c = super()
    c.timespan = @timespan
    c

  afterRender: ->
    super()
