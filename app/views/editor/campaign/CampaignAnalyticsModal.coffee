template = require 'templates/editor/campaign/campaign-analytics-modal'
utils = require 'core/utils'
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

  onClickReloadButton: () =>
    startDay = $('#input-startday').val()
    endDay = $('#input-endday').val()
    delete @campaignCompletions.levels
    @render()
    @getCampaignAnalytics startDay, endDay

  getCampaignAnalytics: (startDay, endDay) =>
    # Fetch campaign analytics, unless dates given

    startDay = startDay.replace(/-/g, '') if startDay?
    endDay = endDay.replace(/-/g, '') if endDay?

    startDay ?= utils.getUTCDay -14
    endDay ?= utils.getUTCDay -1

    success = (data) =>
      return if @destroyed
      mapFn = (item) ->
        item.completionRate = (item.finished / item.started * 100).toFixed(2)
        item
      @campaignCompletions.levels = _.map data, mapFn, @
      sortedLevels = _.cloneDeep @campaignCompletions.levels
      sortedLevels = _.filter sortedLevels, ((a) -> a.finished >= 10), @
      sortedLevels.sort (a, b) -> b.completionRate - a.completionRate
      @campaignCompletions.top3 = _.pluck sortedLevels[0..2], 'level'
      sortedLevels.sort (a, b) -> a.completionRate - b.completionRate
      @campaignCompletions.bottom3 = _.pluck sortedLevels[0..2], 'level'
      @campaignCompletions.startDay = "#{startDay[0..3]}-#{startDay[4..5]}-#{startDay[6..7]}"
      @campaignCompletions.endDay = "#{endDay[0..3]}-#{endDay[4..5]}-#{endDay[6..7]}"
      @getCampaignAveragePlaytimes startDay, endDay

    # TODO: Why do we need this url dash?
    request = @supermodel.addRequestResource 'campaign_completions', {
      url: '/db/analytics_perday/-/campaign_completions'
      data: {startDay: startDay, endDay: endDay, slug: @campaignHandle}
      method: 'POST'
      success: success
    }, 0
    request.load()

  getCampaignAveragePlaytimes: (startDay, endDay) =>
    # Fetch level average playtimes
    success = (data) =>
      return if @destroyed
      levelAverages = {}
      for item in data
        levelAverages[item.level] ?= []
        levelAverages[item.level].push item.average
      for level in @campaignCompletions.levels
        if levelAverages[level.level]
          if levelAverages[level.level].length > 0
            total = _.reduce levelAverages[level.level], ((sum, num) -> sum + num)
            level.averagePlaytime = (total / levelAverages[level.level].length).toFixed(2)
          else
            level.averagePlaytime = 0.0
      @render()

    startDay ?= utils.getUTCDay -14
    startDay = "#{startDay[0..3]}-#{startDay[4..5]}-#{startDay[6..7]}"
    endDay ?= utils.getUTCDay -1
    endDay = "#{endDay[0..3]}-#{endDay[4..5]}-#{endDay[6..7]}"

    levelSlugs = _.pluck @campaignCompletions.levels, 'level'

    request = @supermodel.addRequestResource 'playtime_averages', {
      url: '/db/level/-/playtime_averages'
      data: {startDay: startDay, endDay: endDay, slugs: levelSlugs}
      method: 'POST'
      success: success
    }, 0
    request.load()
