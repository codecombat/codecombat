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
    'click #reload-button': 'onClickReloadButton'
    'dblclick .recent-session': 'onDblClickRecentSession'

  constructor: (options, @level) ->
    super(options)
    @fullLevel = new Level _id: @level.id
    @fullLevel.fetch()
    @listenToOnce @fullLevel, 'sync', => @render?()

    @levelSlug = @level.get('slug')
    @getAnalytics()

  getRenderData: ->
    c = super()
    c.level = if @fullLevel.loaded then @fullLevel else @level
    c.analytics = @analytics
    c

  afterRender: ->
    super()
    $("#input-startday").datepicker dateFormat: "yy-mm-dd"
    $("#input-endday").datepicker dateFormat: "yy-mm-dd"

  onClickClose: ->
    @$el.addClass('hidden')
    @trigger 'hidden'

  onClickReloadButton: () =>
    startDay = $('#input-startday').val()
    endDay = $('#input-endday').val()
    @getAnalytics startDay, endDay

  onDblClickRecentSession: (e) ->
    # Admin view of players' code
    return unless me.isAdmin()
    row = $(e.target).parent()
    player = new User _id: row.data 'player-id'
    session = new LevelSession _id: row.data 'session-id'
    @openModalView new ModelModal models: [session, player]

  getAnalytics: (startDay, endDay) =>
    if startDay?
      startDayDashed = startDay
      startDay = startDay.replace(/-/g, '')
    else
      startDay = utils.getUTCDay -14
      startDayDashed = "#{startDay[0..3]}-#{startDay[4..5]}-#{startDay[6..7]}"
    if endDay?
      endDayDashed = endDay
      endDay = endDay.replace(/-/g, '')
    else 
      endDay = utils.getUTCDay -1
      endDayDashed = "#{endDay[0..3]}-#{endDay[4..5]}-#{endDay[6..7]}"

    @analytics = 
      startDay: startDayDashed
      endDay: endDayDashed
      commonProblems:
        levels: []
        loading: true
      levelCompletions:
        levels: []
        loading: true
      levelHelps:
        levels: []
        loading: true
      levelPlaytimes:
        levels: []
        loading: true
      recentSessions:
        levels: []
        loading: true
    @render()

    @getCommonLevelProblems startDayDashed, endDayDashed, () =>
      @analytics.commonProblems.loading = false
      @render()
    @getLevelCompletions startDay, endDay, () =>
      @analytics.levelCompletions.loading = false
      @render()
    @getLevelHelps startDay, endDay, () =>
      @analytics.levelHelps.loading = false
      @render()
    @getLevelPlaytimes startDayDashed, endDayDashed, () =>
      @analytics.levelPlaytimes.loading = false
      @render()
    @getRecentSessions () =>
      @analytics.recentSessions.loading = false
      @render()

  getCommonLevelProblems: (startDay, endDay, doneCallback) ->
    success = (data) =>
      return doneCallback() if @destroyed
      @analytics.commonProblems.levels = data
      doneCallback()

    # TODO: Why do we need this url dash?
    request = @supermodel.addRequestResource 'common_problems', {
      url: '/db/user_code_problem/-/common_problems'
      data: {startDay: startDay, endDay: endDay, slug: @levelSlug}
      method: 'POST'
      success: success
    }, 0
    request.load()

  getLevelCompletions: (startDay, endDay, doneCallback) ->
    success = (data) =>
      return doneCallback() if @destroyed
      data.sort (a, b) -> if a.created < b.created then 1 else -1
      mapFn = (item) -> 
        item.rate = (item.finished / item.started * 100).toFixed(2)
        item
      @analytics.levelCompletions.levels = _.map data, mapFn, @
      doneCallback()

    request = @supermodel.addRequestResource 'level_completions', {
      url: '/db/analytics_perday/-/level_completions'
      data: {startDay: startDay, endDay: endDay, slug: @levelSlug}
      method: 'POST'
      success: success
    }, 0
    request.load()

  getLevelHelps: (startDay, endDay, doneCallback) ->
    success = (data) =>
      return doneCallback() if @destroyed
      @analytics.levelHelps.levels = data.sort (a, b) -> if a.day < b.day then 1 else -1
      doneCallback()

    request = @supermodel.addRequestResource 'level_helps', {
      url: '/db/analytics_perday/-/level_helps'
      data: {startDay: startDay, endDay: endDay, slugs: [@levelSlug]}
      method: 'POST'
      success: success
    }, 0
    request.load()

  getLevelPlaytimes: (startDay, endDay, doneCallback) ->
    success = (data) =>
      return doneCallback() if @destroyed
      @analytics.levelPlaytimes.levels = data.sort (a, b) -> if a.created < b.created then 1 else -1
      doneCallback()

    request = @supermodel.addRequestResource 'playtime_averages', {
      url: '/db/level/-/playtime_averages'
      data: {startDay: startDay, endDay: endDay, slugs: [@levelSlug]}
      method: 'POST'
      success: success
    }, 0
    request.load()

  getRecentSessions: (doneCallback) ->
    limit = 100

    success = (data) =>
      return doneCallback() if @destroyed
      @analytics.recentSessions.levels = data
      doneCallback()

    # TODO: Why do we need this url dash?
    request = @supermodel.addRequestResource 'level_sessions_recent', {
      url: "/db/level_session/-/recent"
      data: {slug: @levelSlug, limit: limit}
      method: 'POST'
      success: success
    }, 0
    request.load()