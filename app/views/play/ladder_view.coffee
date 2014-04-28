RootView = require 'views/kinds/RootView'
Level = require 'models/Level'
LevelSession = require 'models/LevelSession'
CocoCollection = require 'collections/CocoCollection'
{teamDataFromLevel} = require './ladder/utils'
{me} = require 'lib/auth'
application = require 'application'

LadderTabView = require './ladder/ladder_tab'
MyMatchesTabView = require './ladder/my_matches_tab'
SimulateTabView = require './ladder/simulate_tab'
LadderPlayModal = require './ladder/play_modal'
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
  template: require 'templates/play/ladder'

  subscriptions:
    'application:idle-changed': 'onIdleChanged'

  events:
    'click .play-button': 'onClickPlayButton'
    'click a': 'onClickedLink'

  constructor: (options, @levelID) ->
    super(options)
    @level = @supermodel.loadModel(new Level(_id:@levelID), 'level').model
    @sessions = @supermodel.loadCollection(new LevelSessionsCollection(levelID), 'your_sessions').model
    
    @teams = []

  onLoaded: ->
    @teams = teamDataFromLevel @level
    @render()

  getRenderData: ->
    ctx = super()
    ctx.level = @level
    ctx.link = "/play/level/#{@level.get('name')}"
    ctx.teams = @teams
    ctx.levelID = @levelID
    ctx.levelDescription = marked(@level.get('description')) if @level.get('description')
    ctx._ = _
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
    if hash and not (hash in ['my-matches', 'simulate', 'ladder'])
      @showPlayModal(hash) if @sessions.loaded

  fetchSessionsAndRefreshViews: ->
    return if @destroyed or application.userIsIdle or @$el.find('#simulate.active').length or (new Date() - 2000 < @lastRefreshTime) or not @supermodel.finished()
    @sessions.fetch({"success": @refreshViews})

  refreshViews: =>
    return if @destroyed or application.userIsIdle
    @lastRefreshTime = new Date()
    @ladderTab.refreshLadder()
    @myMatchesTab.refreshMatches()
    console.log "Refreshed sessions for ladder and matches."

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
    SignupModal = require 'views/modal/signup_modal'
    @openModalView(new SignupModal({showRequiredError:true}))

  onClickedLink: (e) ->
    link = $(e.target).closest('a').attr('href')
    if link?.startsWith('/play/level') and me.get('anonymous')
      e.stopPropagation()
      e.preventDefault()
      @showApologeticSignupModal()

  destroy: ->
    clearInterval @refreshInterval
    super()
