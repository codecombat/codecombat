LeaderboardComponent = require('./Leaderboard.vue').default
require('app/styles/play/ladder/new-leaderboard-view.sass')
CocoView = require('views/core/CocoView')
Tournament = require 'models/Tournament'
ModelModal = require 'views/modal/ModelModal'
User = require 'models/User'
LevelSession = require 'models/LevelSession'
TournamentSubmission = require 'models/TournamentSubmission'
store = require('core/store')
silentStore = { commit: _.noop, dispatch: _.noop }
CocoCollection = require 'collections/CocoCollection'
{ LeaderboardData } = require('../LadderTabView')
utils = require 'core/utils'

HIGHEST_SCORE = 1000000


module.exports = class LeaderboardView extends CocoView
  id: 'new-leaderboard-view'
  template: require('templates/play/ladder/leaderboard-view')
  VueComponent: LeaderboardComponent
  constructor: (options, @level, @sessions) ->
    { @league, @tournament } = options
    # params = @collectionParameters(order: -1, scoreOffset: HIGHEST_SCORE, limit: @limit)
    super options
    @tableTitles = [
      {slug: 'creator', col: 0, title: ''},
      {slug: 'language', col: 1, title: ''},
      {slug: 'rank', col: 1, title: $.i18n.t('general.rank')},
      {slug: 'name', col: 3, title: $.i18n.t('general.name')},
      {slug: 'wins', col: 1, title: $.i18n.t('ladder.win_num')},
      {slug: 'losses', col: 1, title: $.i18n.t('ladder.loss_num')},
      {slug: 'win-rate', col: 1, title: $.i18n.t('ladder.win_rate')},
      {slug: 'clan', col: 2, title: $.i18n.t('clans.clan')},
      {slug: 'age', col: 1, title: $.i18n.t('ladder.age_bracket')},
      {slug: 'country', col:1, title: '🏴‍☠️'}
    ]
    @propsData = { @tableTitles, @league, @level, scoreType: 'tournament' }
    unless @tournament
      @propsData.tableTitles = [
        {slug: 'creator', col: 0, title: ''},
        {slug: 'language', col: 1, title: ''},
        {slug: 'rank', col: 1, title: ''},
        {slug: 'name', col: 3, title: $.i18n.t('general.name')},
        {slug: 'score', col: 2, title: $.i18n.t('general.score')},
        {slug: 'age', col: 1, title: $.i18n.t('ladder.age')},
        {slug: 'when', col: 2, title: $.i18n.t('general.when')}
        {slug: 'fight', col: 1, title: ''}
      ]
      @propsData.scoreType = 'arena'
    @rankings = []
    @myRank = -1
    @playerRankings = []
    @session = null
    @dataObj = { myRank: @myRank, rankings: @rankings, session: @session, playerRankings: @playerRankings }

    @refreshLadder()

  render: ->
    super()
    if @leaderboards
      @session = @leaderboards.session
      @myRank = +@leaderboards.myRank
      @rankings = @mapRankings @leaderboards.topPlayers.models
      @playerRankings = @mapRankings @nearbySessions()
    @afterRender()
    @

  onLoaded: -> @render()

  afterRender: ->
    if @vueComponent
      @dataObj.rankings = @rankings
      @dataObj.playerRankings = @playerRankings
      @dataObj.session = @session
      @dataObj.myRank = @myRank
      @$el.find('#new-leaderboard-view').replaceWith(@vueComponent.$el)
    else
      if @vuexModule
        unless _.isFunction(@vuexModule)
          throw new Error('@vuexModule should be a function')
        store.registerModule('page', @vuexModule())

      dataFunction = () => @dataObj
      @vueComponent = new @VueComponent({
        el: @$el.find('new-leaderboard-view')[0]
        propsData: @propsData,
        data: dataFunction,
        store
      })
      @vueComponent.$mount()
      @vueComponent.$on('spectate', (data) =>
        @handleClickSpectateCell(data)
      )
      @vueComponent.$on('click-player-name', (data, nearby) =>
        @handleClickPlayerName(data, nearby)
      )
      @vueComponent.$on('filter-age', (data) =>
        @handleClickAgeFilter(data)
      )
      @vueComponent.$on('load-more', (data) =>
        @onClickLoadMore()
      )

    super(arguments...)

  destroy: ->
    if @vuexModule
      store.unregisterModule('page')
    @vueComponent.$destroy()
    @vueComponent.$store = silentStore
    # ignore all further changes to the store, since the module has been unregistered.
    # may later want to just ignore mutations and actions to the page module.

  nearbySessions: ->
    nearby = @leaderboards.nearbySessions()
    return [] unless nearby.length
    if nearby[0].rank > @rankings.length + 1
      return [{type: 'BLANK_ROW'}].concat nearby
    else
      delta = @rankings.length - nearby[0].rank + 1
      return nearby.slice(delta)

  mapRankings: (data ) ->
    return _.map data, (model, index) =>
      if model?.type == 'BLANK_ROW'
        return model
      if @tournament
        return [
          model.get('creator'),
          model.get('submittedCodeLanguage'),
          index+1,
          (model.get('fullName') || model.get('creatorName') || $.i18n.t("play.anonymous")),
          model.get('wins'),
          model.get('losses'),
          ((model.get('wins') or 0) / (((model.get('wins') or 0) + (model.get('losses') or 0)) or 1) * 100).toFixed(2) + '%',
          @getClanName(model),
          @getAgeBracket(model),
          model.get('creatorCountryCode')
        ]
      else
        return [
          model.get('creator'),
          model.get('submittedCodeLanguage'),
          model.rank || index+1,
          (model.get('fullName') || model.get('creatorName') || $.i18n.t("play.anonymous")),
          @correctScore(model),
          @getAgeBracket(model),
          moment(model.get('submitDate')).fromNow().replace('a few ', ''),
          model.get('_id')
        ]

  refreshLadder: (force) ->
    return if not force and not @league and (new Date() - 2*60*1000 < @lastRefreshTime)
    @lastRefreshTime = new Date()

    @supermodel.resetProgress()
    @ladderLimit ?= parseInt utils.getQueryVariable('top_players', 100)
    @ageBracket ?= null
    if oldLeaderboard = @leaderboards
      @supermodel.removeModelResource oldLeaderboard
      oldLeaderboard.destroy()

    teamSession = _.find @sessions.models, (session) -> session.get('team') is 'humans'
    @leaderboards = new LeaderboardData(@level, 'humans', teamSession, @ladderLimit, @league, @tournament, @ageBracket)
    @leaderboardRes = @supermodel.addModelResource(@leaderboards, 'leaderboard', {cache: false}, 3)
    @leaderboardRes.load()

  onClickLoadMore: ->
    @ladderLimit ?= 100
    @ladderLimit += 100
    @lastRefreshTime = null
    @refreshLadder true

  handleClickSpectateCell: (data) ->
    return unless data.length is 2
    @spectateTargets ?= {}
    leaderboards= {top: @leaderboards.topPlayers.models, nearby: @nearbySessions()}
    if @tournament
      [rank, lkey] = data[0].split('-')
      @spectateTargets.humans = leaderboards[lkey][+rank].get('levelSession')
      [rank, lkey] = data[1].split('-')
      @spectateTargets.ogres = leaderboards[lkey][+rank].get('levelSession')
    else
      [rank, lkey] = data[0].split('-')
      @spectateTargets.humans = leaderboards[lkey][+rank].get('_id')
      [rank, lkey] = data[1].split('-')
      @spectateTargets.ogres = leaderboards[lkey][+rank].get('_id')

  handleClickPlayerName: (id, nearby) ->
    if me.isAdmin()
      leaderboards = if nearby then @nearbySessions() else @leaderboards.topPlayers.models
      sessionId = if @tournament then leaderboards[id].get('levelSession') else leaderboards[id].get('_id')
      session = new LevelSession _id: sessionId
      @supermodel.loadModel session
      @listenToOnce session, 'sync', (_session) =>
        models = [_session]
        unless _session.get('source')?.name
          playerId = if @tournament then leaderboards[id].get('owner') else leaderboards[id].get('creator')
          models.push new User _id: playerId
        if @tournament
          models.push new TournamentSubmission _id: leaderboards[id].get('_id')
        @openModalView new ModelModal models: models
    else if me.isTeacher()
      ;
    else
      ;

  handleClickAgeFilter: (ageBracket) ->
    @ageBracket = ageBracket
    if me.showChinaResourceInfo() and ageBracket == '11-14'
      @ageBracket = '11-18'
    @refreshLadder true

  getClanName: (model) ->
    firstClan = (model.get('creatorClans') ? [])[0] ? {}
    name = firstClan.displayName ? firstClan.name ? ""
    if (!/[a-z]/.test(name))
      name = utils.titleize(name)  # Convert any all-uppercase clan names to title-case
    name

  getAgeBracket: (model) ->
    $.i18n.t("ladder.bracket_#{(model.get('ageBracket') || 'open').replace(/-/g, '_')}")

  correctScore: (model) ->
    sessionStats = if @league then _.find(model.get('leagues'), {leagueID: @league.id})?.stats else model.attributes
    return (sessionStats?.totalScore || model.get('totalScore')/2) * 100 | 0
