Campaign = require 'models/Campaign'
CocoCollection = require 'collections/CocoCollection'

module.exports = class Campaigns extends CocoCollection
  model: Campaign
  url: '/db/campaign'

  initialize: (models, @options = {}) ->
    @forceCourseNumbering = @options.forceCourseNumbering
    super(arguments...)

  _prepareModel: (model, options) ->
    model.forceCourseNumbering = @forceCourseNumbering
    super(arguments...)

  fetchByType: (type, options={}) ->
    options.data ?= {}
    options.data.type = type
    @fetch(options)
    
  fetchCampaignsAndRelatedLevels: (options={}, levelOptions={}) ->
    Levels = require 'collections/Levels'
    options.data ?= {}
    options.data.project = 'slug'
    exclude = options.exclude or []
    return @fetch(options)
      .then =>
        toRemove = @filter (c) -> c.get('slug') in exclude
        @remove toRemove
        levelOptions.data ?= {}
        levelOptions.data.project ?= 'thangs,name,slug,campaign,tasks'
        jqxhrs = []
        for campaign in @models
          campaign.levels = new Levels()
          jqxhrs.push campaign.levels.fetchForCampaign(campaign.get('slug'), levelOptions)
        return $.when(jqxhrs...)
