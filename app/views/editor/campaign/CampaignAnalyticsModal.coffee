template = require 'templates/editor/campaign/campaign-analytics-modal'
utils = require 'core/utils'
require 'vendor/d3'
ModalView = require 'views/core/ModalView'

# TODO: jquery-ui datepicker doesn't work well in this view
# TODO: the date format handling is confusing (yyyy-mm-dd <=> yyyymmdd)

module.exports = class CampaignAnalyticsModal extends ModalView
  id: 'campaign-analytics-modal'
  template: template
  plain: true

  events:
    'click #reload-button': 'onClickReloadButton'

  constructor: (options, @campaignHandle, @campaignCompletions) ->
    super options
    @getCampaignAnalytics() unless @campaignCompletions?.levels?

  getRenderData: ->
    c = super()
    c.campaignCompletions = @campaignCompletions
    c

  afterRender: ->
    super()
    $("#input-startday").datepicker dateFormat: "yy-mm-dd"
    $("#input-endday").datepicker dateFormat: "yy-mm-dd"
    @addCompletionLineGraphs()

  addCompletionLineGraphs: ->
    return unless @campaignCompletions.levels
    for level in @campaignCompletions.levels
      days = []
      for day of level['days']
        continue unless level['days'][day].started > 0
        days.push
          day: day
          rate: level['days'][day].finished / level['days'][day].started
      days.sort (a, b) -> a.day - b.day
      data = []
      for i in [0...days.length]
        data.push
          x: i
          y: days[i].rate
      @addLineGraph '#background' + level.level, data

  addLineGraph: (containerSelector, lineData, lineColor='green', min=0, max=1.0) ->
    # Add a line chart to the given container
    # TODO: Move this to a utility library
    vis = d3.select(containerSelector)
    width = $(containerSelector).width()
    height = $(containerSelector).height()
    xRange = d3.scale.linear().range([0, width]).domain([d3.min(lineData, (d) -> d.x), d3.max(lineData, (d) -> d.x)])
    yRange = d3.scale.linear().range([height, 0]).domain([min, max])
    xAxis = d3.svg.axis()
      .scale(xRange)
      .tickSize(5)
      .tickSubdivide(true)
    yAxis = d3.svg.axis()
      .scale(yRange)
      .tickSize(5)
      .orient('left')
      .tickSubdivide(true)
    vis.append('svg:g')
      .attr('class', 'x axis')
      .attr('transform', 'translate(0,' + height + ')')
      .call(xAxis)
    vis.append('svg:g')
      .attr('class', 'y axis')
      .attr('transform', 'translate(0,0)')
      .call(yAxis)
    lineFunc = d3.svg.line()
      .x((d) -> xRange(d.x))
      .y((d) -> yRange(d.y))
      .interpolate('linear')
    vis.append('svg:path')
      .attr('d', lineFunc(lineData))
      .attr('stroke', lineColor)
      .attr('stroke-width', 1)
      .attr('fill', 'none')

  onClickReloadButton: () =>
    startDay = $('#input-startday').val()
    endDay = $('#input-endday').val()
    delete @campaignCompletions.levels
    @campaignCompletions.startDay = startDay
    @campaignCompletions.endDay = endDay
    @render()
    @getCampaignAnalytics startDay, endDay

  getCampaignAnalytics: (startDay, endDay) =>
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
    @campaignCompletions.startDay = startDayDashed
    @campaignCompletions.endDay = endDayDashed

    # Chain these together so we can calculate relative metrics (e.g. left game per second)
    @getCampaignLevelCompletions startDay, endDay, () =>
      @render()
      @getCompaignLevelDrops startDay, endDay, () =>
        @render()
        @getCampaignAveragePlaytimes startDayDashed, endDayDashed, () =>
          @render()

  getCampaignAveragePlaytimes: (startDay, endDay, doneCallback) =>
    # Fetch level average playtimes
    # Needs date format yyyy-mm-dd
    success = (data) =>
      return if @destroyed
      # console.log 'getCampaignAveragePlaytimes success', data
      levelAverages = {}
      maxPlaytime = 0
      for item in data
        levelAverages[item.level] ?= []
        levelAverages[item.level].push item.average
      for level in @campaignCompletions.levels
        if levelAverages[level.level]
          if levelAverages[level.level].length > 0
            total = _.reduce levelAverages[level.level], ((sum, num) -> sum + num)
            level.averagePlaytime = total / levelAverages[level.level].length
            maxPlaytime = level.averagePlaytime if maxPlaytime < level.averagePlaytime
            if level.averagePlaytime > 0 and level.dropped > 0
              level.droppedPerSecond = level.dropped / level.averagePlaytime
          else
            level.averagePlaytime = 0.0

      addPlaytimePercentage = (item) ->
        item.playtimePercentage = Math.round(item.averagePlaytime / maxPlaytime * 100.0) unless maxPlaytime is 0
        item
      @campaignCompletions.levels = _.map @campaignCompletions.levels, addPlaytimePercentage, @

      sortedLevels = _.cloneDeep @campaignCompletions.levels
      sortedLevels = _.filter sortedLevels, ((a) -> a.droppedPerSecond > 0), @
      sortedLevels.sort (a, b) -> b.droppedPerSecond - a.droppedPerSecond
      @campaignCompletions.top3DropPerSecond = _.pluck sortedLevels[0..2], 'level'
      doneCallback()

    levelSlugs = _.pluck @campaignCompletions.levels, 'level'

    request = @supermodel.addRequestResource 'playtime_averages', {
      url: '/db/level/-/playtime_averages'
      data: {startDay: startDay, endDay: endDay, slugs: levelSlugs}
      method: 'POST'
      success: success
    }, 0
    request.load()

  getCampaignLevelCompletions: (startDay, endDay, doneCallback) =>
    # Needs date format yyyymmdd
    success = (data) =>
      return if @destroyed
      # console.log 'getCampaignLevelCompletions success', data
      countCompletions = (item) ->
        item.started = _.reduce item.days, ((result, current) -> result + current.started), 0
        item.finished = _.reduce item.days, ((result, current) -> result + current.finished), 0
        item.completionRate = if item.started > 0 then item.finished / item.started * 100 else 0.0
        item
      addUserRemaining = (item) ->
        item.usersRemaining = Math.round(item.started / maxStarted * 100.0) unless maxStarted is 0
        item

      @campaignCompletions.levels = _.map data, countCompletions, @
      if @campaignCompletions.levels.length > 0 
        maxStarted = (_.max @campaignCompletions.levels, ((a) -> a.started)).started
      else
        maxStarted = 0
      @campaignCompletions.levels = _.map @campaignCompletions.levels, addUserRemaining, @

      sortedLevels = _.cloneDeep @campaignCompletions.levels
      sortedLevels = _.filter sortedLevels, ((a) -> a.finished >= 10), @
      if sortedLevels.length >= 3
        sortedLevels.sort (a, b) -> b.completionRate - a.completionRate
        @campaignCompletions.top3 = _.pluck sortedLevels[0..2], 'level'
        @campaignCompletions.bottom3 = _.pluck sortedLevels[sortedLevels.length - 4...sortedLevels.length - 1], 'level'

      doneCallback()

    # TODO: Why do we need this url dash?
    request = @supermodel.addRequestResource 'campaign_completions', {
      url: '/db/analytics_perday/-/campaign_completions'
      data: {startDay: startDay, endDay: endDay, slug: @campaignHandle}
      method: 'POST'
      success: success
    }, 0
    request.load()

  getCompaignLevelDrops: (startDay, endDay, doneCallback) =>
    # Fetch level drops
    # Needs date format yyyymmdd
    success = (data) =>
      return if @destroyed
      # console.log 'getCompaignLevelDrops success', data
      levelDrops = {}
      for item in data
        levelDrops[item.level] ?= item.dropped
      for level in @campaignCompletions.levels
        level.dropped = levelDrops[level.level] ? 0
        level.dropPercentage = if level.started > 0 then level.dropped / level.started * 100 else 0.0

      sortedLevels = _.cloneDeep @campaignCompletions.levels
      sortedLevels = _.filter sortedLevels, ((a) -> a.dropPercentage > 0), @
      if sortedLevels.length >= 3
        sortedLevels.sort (a, b) -> b.dropPercentage - a.dropPercentage
        @campaignCompletions.top3DropPercentage = _.pluck sortedLevels[0..2], 'level'
      doneCallback()

    return unless @campaignCompletions?.levels?
    levelSlugs = _.pluck @campaignCompletions.levels, 'level'

    request = @supermodel.addRequestResource 'level_drops', {
      url: '/db/analytics_perday/-/level_drops'
      data: {startDay: startDay, endDay: endDay, slugs: levelSlugs}
      method: 'POST'
      success: success
    }, 0
    request.load()
