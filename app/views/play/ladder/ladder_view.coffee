RootView = require 'views/kinds/RootView'
Level = require 'models/Level'
LevelSession = require 'models/LevelSession'
CocoCollection = require 'collections/CocoCollection'
{teamDataFromLevel} = require './utils'
{me} = require 'lib/auth'
application = require 'application'

LadderTabView = require './ladder_tab'
MyMatchesTabView = require './my_matches_tab'
SimulateTabView = require './simulate_tab'
LadderPlayModal = require './play_modal'
CocoClass = require 'lib/CocoClass'


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

  subscriptions:
    'application:idle-changed': 'onIdleChanged'

  events:
    'click .play-button': 'onClickPlayButton'
    'click a:not([data-toggle])': 'onClickedLink'

  constructor: (options, @levelID) ->
    super(options)
    @level = @supermodel.loadModel(new Level(_id:@levelID), 'level').model
    @sessions = @supermodel.loadCollection(new LevelSessionsCollection(levelID), 'your_sessions').model

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
    ctx.tournamentTimeLeft = moment(new Date(1402444800000)).fromNow()
    ctx.winners = require('views/play/ladder/tournament_results')[@levelID]
    ctx

  afterRender: ->
    super()
    # console.debug 'gintau', 'ladder_view-afterRender', @supermodel.finished()
    return unless @supermodel.finished()
    @insertSubView(@ladderTab = new LadderTabView({}, @level, @sessions))
    @insertSubView(@myMatchesTab = new MyMatchesTabView({}, @level, @sessions))
    @insertSubView(@simulateTab = new SimulateTabView())
    @refreshInterval = setInterval(@fetchSessionsAndRefreshViews.bind(@), 20 * 1000)
    hash = document.location.hash[1..] if document.location.hash
    if hash and not (hash in ['my-matches', 'simulate', 'ladder', 'prizes', 'rules'])
      @showPlayModal(hash) if @sessions.loaded

  fetchSessionsAndRefreshViews: ->
    return if @destroyed or application.userIsIdle or (new Date() - 2000 < @lastRefreshTime) or not @supermodel.finished()
    @sessions.fetch({"success": @refreshViews})

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

  showPlayModal: (teamID) ->
    return @showApologeticSignupModal() if me.get('anonymous')
    session = (s for s in @sessions.models when s.get('team') is teamID)[0]
    modal = new LadderPlayModal({}, @level, session, teamID)
    @openModalView modal

  showApologeticSignupModal: ->
    SignupModal = require 'views/modal/auth_modal'
    @openModalView(new SignupModal({showRequiredError:true}))

  onClickedLink: (e) ->
    link = $(e.target).closest('a').attr('href')
    if link?.startsWith('/play/level') and me.get('anonymous')
      e.stopPropagation()
      e.preventDefault()
      @showApologeticSignupModal()
    if link and /#rules$/.test link
      @$el.find('a[href="#rules"]').tab('show')
    if link and /#prizes/.test link
      @$el.find('a[href="#prizes"]').tab('show')

  destroy: ->
    clearInterval @refreshInterval
    super()
