require('app/styles/user/certificates-view.sass')
RootView = require 'views/core/RootView'
User = require 'models/User'
LevelSession = require 'models/LevelSession'
Levels = require 'collections/Levels'
Level = require 'models/Level'
utils = require 'core/utils'
Campaign = require 'models/Campaign'

# This certificate is generated anonymously. This requires the certificate
# to be generated only from query params.
# Requires campaign slug query param as well as username param.
module.exports = class AnonCertificatesView extends RootView
  id: 'certificates-view'
  template: require 'templates/user/certificates-anon-view.pug'

  events:
    'click .print-btn': 'onClickPrintButton'

  initialize: (options, userId) ->
    @loading = true
    user = new User _id:userId
    userPromise = user.fetch()
    campaignSlug = utils.getQueryVariable 'campaign'
    @name = utils.getQueryVariable 'username'
    levelsPromise = (new Levels()).fetchForCampaign(campaignSlug, {})
    sessionsPromise = levelsPromise
      .then((l)=>
        return Promise.all(
          l.map((x)=>x._id)
            .map(@fetchLevelSession)
        )
    )

    # Initial data.
    @courseStats = {
      levels: {
        numDone: 0
      },
      linesOfCode: 0,
      courseComplete: true
    }

    Promise.all([userPromise, levelsPromise, sessionsPromise])
      .then(([u, l, ls]) =>
        ls = ls.map((data)=> new LevelSession(data))
        l = l.map((data)=> new Level(data))
        @concepts = @loadConcepts(l)
        @courseStats = @reduceSessionStats(ls, l)
        @loading = false
        @render()
    )

  backgroundImage: ->
    "/images/pages/user/certificates/backgrounds/background-" + "hoc" + ".png"

  getMedallion: ->
    '/images/pages/user/certificates/medallions/medallion-' + 'gd3' + '.png'

  onClickPrintButton: ->
    window.print()

  userName: ->
    @name || "Lorem Ipsum Name"

  getCodeLanguageName: ->
    "Python"

  loadConcepts:(levels) ->
    allConcepts = levels
      .map((l)=>l.get("concepts"))
      .reduce((m, c) =>
        return m.concat(c)
      , [])

    concepts = []
    (new Set(allConcepts))
      .forEach((v) => concepts.push(v))
    return concepts

  getConcepts:->
    @concepts

  fetchLevelSession:(levelID) ->
    url = "/db/level/#{levelID}/session"
    session = new LevelSession()
    return session.fetch({url: url})

  reduceSessionStats: (sessions, levels) ->
    return sessions.reduce((stats, ls, i) =>
      stats.levels.numDone += 1
      stats.linesOfCode += ls.countOriginalLinesOfCode(levels[i])
      return stats
    , @courseStats)
