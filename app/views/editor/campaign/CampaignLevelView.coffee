CocoView = require 'views/core/CocoView'
Level = require 'models/Level'

module.exports = class CampaignLevelView extends CocoView
  id: 'campaign-level-view'
  template: require 'templates/editor/campaign/campaign-level-view'

  events:
    'click .close': 'onClickClose'

  constructor: (options, @level) ->
    super(options)
    @fullLevel = new Level _id: @level.id
    @fullLevel.fetch()
    @listenToOnce @fullLevel, 'sync', => @render?()

    @levelSlug = @level.get('slug')
    @getCommonLevelProblems()
    @getLevelCompletions()
    @getLevelPlaytimes()

  getRenderData: ->
    c = super()
    c.level = if @fullLevel.loaded then @fullLevel else @level
    c.commonProblems = @commonProblems
    c.levelCompletions = @levelCompletions
    c.levelPlaytimes = @levelPlaytimes
    c

  onClickClose: ->
    @$el.addClass('hidden')
    @trigger 'hidden'

  getCommonLevelProblems: ->
    # Fetch last 30 days of common level problems
    startDay = new Date()
    startDay.setDate(startDay.getUTCDate() - 29)
    startDay = startDay.getUTCFullYear() + '-' + (startDay.getUTCMonth() + 1) + '-' + startDay.getUTCDate()

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
    # Fetch last 7 days of level completion counts
    success = (data) =>
      return if @destroyed
      data.sort (a, b) -> if a.created < b.created then 1 else -1
      mapFn = (item) -> 
        item.rate = (item.finished / item.started * 100).toFixed(2)
        item
      @levelCompletions = _.map data, mapFn, @
      @render()

    startDay = new Date()
    startDay.setDate(startDay.getUTCDate() - 6)
    startDay = startDay.getUTCFullYear() + '-' + (startDay.getUTCMonth() + 1) + '-' + startDay.getUTCDate()
    
    # TODO: Why do we need this url dash?
    request = @supermodel.addRequestResource 'level_completions', {
      url: '/db/analytics_log_event/-/level_completions'
      data: {startDay: startDay, slug: @levelSlug}
      method: 'POST'
      success: success
    }, 0
    request.load()

  getLevelPlaytimes: ->
    # Fetch last 7 days of level average playtimes
    success = (data) =>
      return if @destroyed
      @levelPlaytimes = data.sort (a, b) -> if a.created < b.created then 1 else -1
      @render()

    startDay = new Date()
    startDay.setDate(startDay.getUTCDate() - 6)
    startDay = startDay.getUTCFullYear() + '-' + (startDay.getUTCMonth() + 1) + '-' + startDay.getUTCDate()
    
    # TODO: Why do we need this url dash?
    request = @supermodel.addRequestResource 'playtime_averages', {
      url: '/db/level/-/playtime_averages'
      data: {startDay: startDay, slugs: [@levelSlug]}
      method: 'POST'
      success: success
    }, 0
    request.load()
