LeaderboardComponent = require('./Leaderboard.vue').default
CocoView = require('views/core/CocoView')
Tournament = require 'models/Tournament'
store = require('core/store')
silentStore = { commit: _.noop, dispatch: _.noop }
CocoCollection = require 'collections/CocoCollection'
{ LeaderboardData } = require('../LadderTabView')
utils = require 'core/utils'

HIGHEST_SCORE = 1000000

class TournamentLeaderboardCollection extends CocoCollection
  url: ''
  model: Tournament

  constructor: (tournamentId, options) ->
    super()
    @url = "/db/tournament/#{tournamentId}/rankings?#{$.param(options)}"



module.exports = class LeaderboardView extends CocoView
  id: 'ladder-tab-view'
  template: require('templates/play/ladder/leaderboard-view')
  VueComponent: LeaderboardComponent
  constructor: (options, @level, @sessions) ->
    { @league, @tournament } = options
    # params = @collectionParameters(order: -1, scoreOffset: HIGHEST_SCORE, limit: @limit)
    super options
    @tableTitles = [
      {slug: 'language', col: 1, title: ''},
      {slug: 'rank', col: 1, title: 'Rank'},
      {slug: 'name', col: 3, title: 'Name'},
      {slug: 'wins', col: 1, title: 'Wins'},
      {slug: 'losses', col: 1, title: 'Losses'},
      {slug: 'clan', col: 3, title: 'Clan'},
      {slug: 'age', col: 1, title: 'Age'},
      {slug: 'country', col:1, title: '🏴‍☠️'}
    ]
    @rankings = []
    @dataObj = { rankings: @rankings }
    @propsData = { @tableTitles }
    @refreshLadder()


  render: ->
    super()
    if @leaderboards
      @rankings = _.map @leaderboards.topPlayers.models, (model) =>
        return [
          'cpp',
          1,
          (model.get('fullName') || model.get('creatorName') || $t("play.anonymous")),
          model.get('wins'),
          model.get('losses'),
          @getClanName(model),
          5,
        ]

    @afterRender()
    @

  onLoaded: -> @render()

  afterRender: ->
    if @vueComponent
      @dataObj.rankings = @rankings
      @$el.find('#ladder-tab-view').replaceWith(@vueComponent.$el)
    else
      if @vuexModule
        unless _.isFunction(@vuexModule)
          throw new Error('@vuexModule should be a function')
        store.registerModule('page', @vuexModule())

      dataFunction = () => @dataObj
      @vueComponent = new @VueComponent({
        el: @$el.find('#ladder-tab-view')[0]
        propsData: @propsData,
        data: dataFunction,
        store
      })
      @vueComponent.$mount()

    super(arguments...)

  destroy: ->
    if @vuexModule
      store.unregisterModule('page')
    @vueComponent.$destroy()
    @vueComponent.$store = silentStore
    # ignore all further changes to the store, since the module has been unregistered.
    # may later want to just ignore mutations and actions to the page module.

  refreshLadder: ->
    return if not @league and (new Date() - 2*60*1000 < @lastRefreshTime)
    @lastRefreshTime = new Date()

    @supermodel.resetProgress()
    @ladderLimit ?= parseInt utils.getQueryVariable('top_players', 100)
    if oldLeaderboard = @leaderboards
      @supermodel.removeModelResource oldLeaderboard
      oldLeaderboard.destroy()

    teamSession = _.find @sessions.models, (session) -> session.get('team') is 'humans'
    @leaderboards = new LeaderboardData(@level, 'humans', teamSession, @ladderLimit, @league, @tournament)
    @leaderboardRes = @supermodel.addModelResource(@leaderboards, 'leaderboard', {cache: false}, 3)
    @leaderboardRes.load()


  getClanName: (model) ->
    firstClan = (model.get('creatorClans') ? [])[0] ? {}
    name = firstClan.displayName ? firstClan.name ? ""
    if (!/a-z/.test(name))
      name = utils.titleize(name)  # Convert any all-uppercase clan names to title-case
    name
 
  getAgeBracket: (model) ->
    $.i18n.t("ladder.bracket_#{(model.get('ageBracket') || 'open').replace(/-/g, '_')}")
