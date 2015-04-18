RootView = require 'views/core/RootView'
Level = require 'models/Level'
LevelSession = require 'models/LevelSession'
CocoCollection = require 'collections/CocoCollection'
{teamDataFromLevel} = require './utils'
{me} = require 'core/auth'
application = require 'core/application'

LadderTabView = require './LadderTabView'
MyMatchesTabView = require './MyMatchesTabView'
SimulateTabView = require './SimulateTabView'
LadderPlayModal = require './LadderPlayModal'
CocoClass = require 'core/CocoClass'

HIGHEST_SCORE = 1000000

class LevelSessionsCollection extends CocoCollection
  url: ''
  model: LevelSession

  constructor: (levelID) ->
    super()
    @url = "/db/level/#{levelID}/my_sessions"

module.exports = class LadderView extends RootView
  id: 'ladder-view'
  template: require 'templates/play/ladder/ladder'
  usesSocialMedia: true

  subscriptions:
    'application:idle-changed': 'onIdleChanged'

  events:
    'click .play-button': 'onClickPlayButton'
    'click a:not([data-toggle])': 'onClickedLink'
    'click .spectate-button': 'onClickSpectateButton'

  constructor: (options, @levelID) ->
    super(options)
    @level = @supermodel.loadModel(new Level(_id: @levelID), 'level').model
    @sessions = @supermodel.loadCollection(new LevelSessionsCollection(@levelID), 'your_sessions', {cache: false}).model

    @teams = []

  onLoaded: ->
    @teams = teamDataFromLevel @level
    super()

  getRenderData: ->
    ctx = super()
    ctx.level = @level
    ctx.link = "/play/level/#{@level.get('name')}"
    ctx.teams = @teams
    ctx.levelID = @levelID
    ctx.levelDescription = marked(@level.get('description')) if @level.get('description')
    ctx._ = _
    if tournamentEndDate = {greed: 1402444800000, 'criss-cross': 1410912000000, 'zero-sum': 1428364800000}[@levelID]
      ctx.tournamentTimeLeft = moment(new Date(tournamentEndDate)).fromNow()
    if tournamentStartDate = {'zero-sum': 1427472000000}[@levelID]
      ctx.tournamentTimeElapsed = moment(new Date(tournamentStartDate)).fromNow()
    ctx.winners = require('./tournament_results')[@levelID]
    ctx

  afterRender: ->
    super()
    return unless @supermodel.finished()
    @insertSubView(@ladderTab = new LadderTabView({}, @level, @sessions))
    @insertSubView(@myMatchesTab = new MyMatchesTabView({}, @level, @sessions))
    @insertSubView(@simulateTab = new SimulateTabView())
    @refreshInterval = setInterval(@fetchSessionsAndRefreshViews.bind(@), 60 * 1000)
    hash = document.location.hash[1..] if document.location.hash
    if hash and not (hash in ['my-matches', 'simulate', 'ladder', 'prizes', 'rules', 'winners'])
      @showPlayModal(hash) if @sessions.loaded

  fetchSessionsAndRefreshViews: ->
    return if @destroyed or application.userIsIdle or (new Date() - 2000 < @lastRefreshTime) or not @supermodel.finished()
    @sessions.fetch success: @refreshViews, cache: false

  refreshViews: =>
    return if @destroyed or application.userIsIdle
    @lastRefreshTime = new Date()
    @ladderTab.refreshLadder()
    @myMatchesTab.refreshMatches()
    @simulateTab.refresh()

  onIdleChanged: (e) ->
    @fetchSessionsAndRefreshViews() unless e.idle

  onClickPlayButton: (e) ->
    @showPlayModal($(e.target).closest('.play-button').data('team'))

  onClickSpectateButton: (e) ->
    humanSession = @ladderTab.spectateTargets?.humans
    ogreSession = @ladderTab.spectateTargets?.ogres
    console.log humanSession, ogreSession
    return unless humanSession and ogreSession
    e.preventDefault()
    e.stopImmediatePropagation()
    url = "/play/spectate/#{@level.get('slug')}?session-one=#{humanSession}&session-two=#{ogreSession}"
    Backbone.Mediator.publish 'router:navigate', route: url

  showPlayModal: (teamID) ->
    session = (s for s in @sessions.models when s.get('team') is teamID)[0]
    modal = new LadderPlayModal({}, @level, session, teamID)
    @openModalView modal

  onClickedLink: (e) ->
    link = $(e.target).closest('a').attr('href')
    if link and /#rules$/.test link
      @$el.find('a[href="#rules"]').tab('show')
    if link and /#prizes/.test link
      @$el.find('a[href="#prizes"]').tab('show')
    if link and /#winners/.test link
      @$el.find('a[href="#winners"]').tab('show')

  destroy: ->
    clearInterval @refreshInterval
    super()
