CocoView = require 'views/core/CocoView'
Level = require 'models/Level'
LevelSession = require 'models/LevelSession'
ModelModal = require 'views/modal/ModelModal'
User = require 'models/User'
utils = require 'core/utils'

module.exports = class CampaignLevelView extends CocoView
  id: 'campaign-level-view'
  template: require 'templates/editor/campaign/campaign-level-view'

  events:
    'click .close': 'onClickClose'
    'dblclick .recent-session': 'onDblClickRecentSession'

  constructor: (options, @level) ->
    super(options)
    @fullLevel = new Level _id: @level.id
    @fullLevel.fetch()
    @listenToOnce @fullLevel, 'sync', => @render?()

    @levelSlug = @level.get('slug')
    @getCommonLevelProblems()
    @getLevelCompletions()
    @getLevelPlaytimes()
    @getRecentSessions()

  getRenderData: ->
    c = super()
    c.level = if @fullLevel.loaded then @fullLevel else @level
    c.commonProblems = @commonProblems
    c.levelCompletions = @levelCompletions
    c.levelPlaytimes = @levelPlaytimes
    c.recentSessions = @recentSessions
    c

  onClickClose: ->
    @$el.addClass('hidden')
    @trigger 'hidden'

  onDblClickRecentSession: (e) ->
    # Admin view of players' code
    return unless me.isAdmin()
    row = $(e.target).parent()
    player = new User _id: row.data 'player-id'
    session = new LevelSession _id: row.data 'session-id'
    @openModalView new ModelModal models: [session, player]

  getCommonLevelProblems: ->
    # Fetch last 30 days of common level problems
    startDay = utils.getUTCDay -29
    startDay = "#{startDay[0..3]}-#{startDay[4..5]}-#{startDay[6..7]}"

    success = (data) =>
      return if @destroyed
      @commonProblems = data
      @commonProblems.startDay = startDay
      @render()

    # TODO: Why do we need this url dash?
    request = @supermodel.addRequestResource 'common_problems', {
      url: '/db/user_code_problem/-/common_problems'
      data: {startDay: startDay, slug: @levelSlug}
      method: 'POST'
      success: success
    }, 0
    request.load()

  getLevelCompletions: ->
    # Fetch last 14 days of level completion counts
    success = (data) =>
      return if @destroyed
      data.sort (a, b) -> if a.created < b.created then 1 else -1
      mapFn = (item) -> 
        item.rate = (item.finished / item.started * 100).toFixed(2)
        item
      @levelCompletions = _.map data, mapFn, @
      @render()

    startDay = utils.getUTCDay -14
    
    # TODO: Why do we need this url dash?
    request = @supermodel.addRequestResource 'level_completions', {
      url: '/db/analytics_perday/-/level_completions'
      data: {startDay: startDay, slug: @levelSlug}
      method: 'POST'
      success: success
    }, 0
    request.load()

  getLevelPlaytimes: ->
    # Fetch last 14 days of level average playtimes
    success = (data) =>
      return if @destroyed
      @levelPlaytimes = data.sort (a, b) -> if a.created < b.created then 1 else -1
      @render()

    startDay = utils.getUTCDay -13
    startDay = "#{startDay[0..3]}-#{startDay[4..5]}-#{startDay[6..7]}"

    # TODO: Why do we need this url dash?
    request = @supermodel.addRequestResource 'playtime_averages', {
      url: '/db/level/-/playtime_averages'
      data: {startDay: startDay, slugs: [@levelSlug]}
      method: 'POST'
      success: success
    }, 0
    request.load()

  getRecentSessions: ->
    limit = 100

    success = (data) =>
      return if @destroyed
      @recentSessions = data
      @render()

    # TODO: Why do we need this url dash?
    request = @supermodel.addRequestResource 'level_sessions_recent', {
      url: "/db/level_session/-/recent"
      data: {slug: @levelSlug, limit: limit}
      method: 'POST'
      success: success
    }, 0
    request.load()