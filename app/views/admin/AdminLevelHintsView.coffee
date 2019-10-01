require('app/styles/admin/admin-level-hints.sass')
RootView = require 'views/core/RootView'
CocoCollection = require 'collections/CocoCollection'
Article = require 'models/Article'
Level = require 'models/Level'
Campaign = require 'models/Campaign'
Course = require 'models/Course'
utils = require 'core/utils'

module.exports = class AdminLevelHintsView extends RootView
  id: 'admin-level-hints-view'
  template: require 'templates/admin/admin-level-hints'

  initialize: ->
    return super() unless me.isAdmin()
    @articles = new CocoCollection([], { url: "/db/article", model: Article})
    @supermodel.loadCollection(@articles, 'articles')
    @courses = new CocoCollection([], { url: "/db/course", model: Course})
    @supermodel.loadCollection(@courses, 'courses')
    @campaigns = new CocoCollection([], { url: "/db/campaign?project=levels,slug", model: Campaign})
    @supermodel.loadCollection(@campaigns, 'campaigns')
    super()

  onLoaded: ->
    orderedCampaignSlugs = ['dungeon', 'campaign-game-dev-1', 'campaign-web-dev-1', 'forest', 'campaign-game-dev-2', 'campaign-web-dev-2', 'desert', 'mountain', 'glacier']
    courseCampaignIds = []
    for course in utils.sortCourses(@courses.models).reverse()
      if course.get('releasePhase') is 'released'
        campaign = _.find @campaigns.models, (c) => c.id is course.get('campaignID')
        if campaign
          orderedCampaignSlugs.splice(0, 0, campaign.get('slug'))

    batchSize = 1000
    fetchLevelSessions = (skip, results) =>
      levelPromises = []
      for i in [0..4]
        levelPromise = Promise.resolve($.get("/db/level?skip=#{skip}&project=slug,documentation,original"))
        levelPromises.push(levelPromise)
        skip += batchSize
      new Promise((resolve) -> setTimeout(resolve.bind(null, Promise.all(levelPromises)), 100))
      .then (resultsMatrix) =>
        for newResults in resultsMatrix
          results = results.concat(newResults)
        if results % batchSize is 0
          fetchLevelSessions(skip, results)
        else
          Promise.resolve(results)
    fetchLevelSessions(0, [])
    .then (levels) =>
      levelHintsMap = {}
      for level in levels
        docs = level.documentation ? {}
        general = _.filter (_.find(@articles.models, (article) -> article.get('original') is doc.original)?.attributes for doc in docs.generalArticles or [])
        specific = _.filter(docs.specificArticles or [], (a) => a?)
        hints = (docs.hintsB or docs.hints or []).concat(specific).concat(general)
        hints = _.sortBy hints, (doc) ->
          return -1 if doc.name is 'Intro'
          return 0
        levelHintsMap[level.slug] = hints
      @campaignHints = []
      for campaign in @campaigns.models
        continue unless campaign.get('slug') in orderedCampaignSlugs
        campaignData = {id: campaign.id, slug: campaign.get('slug'), levels: []}
        for levelId of campaign.get('levels')
          level = campaign.get('levels')[levelId]
          campaignData.levels.push({id: levelId, slug: level.slug, hints: levelHintsMap[level.slug] or []})
        @campaignHints.push(campaignData)

      @campaignHints.sort((a, b) => orderedCampaignSlugs.indexOf(a.slug) - orderedCampaignSlugs.indexOf(b.slug))
      @render?()
