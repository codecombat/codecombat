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

Clan = require 'models/Clan'
CourseInstance = require 'models/CourseInstance'
Course = require 'models/Course'

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

  initialize: (options, @levelID, @leagueType, @leagueID) ->
    @level = @supermodel.loadModel(new Level(_id: @levelID)).model
    @level.once 'sync', =>
      @levelDescription = marked(@level.get('description')) if @level.get('description')
      @teams = teamDataFromLevel @level
    @sessions = @supermodel.loadCollection(new LevelSessionsCollection(@levelID), 'your_sessions', {cache: false}).model
    @winners = require('./tournament_results')[@levelID]

    if tournamentEndDate = {greed: 1402444800000, 'criss-cross': 1410912000000, 'zero-sum': 1428364800000, 'ace-of-coders': 1444867200000}[@levelID]
      @tournamentTimeLeft = moment(new Date(tournamentEndDate)).fromNow()
    if tournamentStartDate = {'zero-sum': 1427472000000, 'ace-of-coders': 1442417400000}[@levelID]
      @tournamentTimeElapsed = moment(new Date(tournamentStartDate)).fromNow()

    @loadLeague()

  loadLeague: ->
    @leagueID = @leagueType = null unless @leagueType in ['clan', 'course']
    return unless @leagueID
    modelClass = if @leagueType is 'clan' then Clan else CourseInstance
    @league = @supermodel.loadModel(new modelClass(_id: @leagueID)).model
    if @leagueType is 'course'
      if @league.loaded
        @onCourseInstanceLoaded @league
      else
        @listenToOnce @league, 'sync', @onCourseInstanceLoaded

  onCourseInstanceLoaded: (courseInstance) ->
    return if @destroyed
    course = new Course({_id: courseInstance.get('courseID')})
    @course = @supermodel.loadModel(course).model
    @listenToOnce @course, 'sync', @render

  afterRender: ->
    super()
    return unless @supermodel.finished()
    @insertSubView(@ladderTab = new LadderTabView({league: @league}, @level, @sessions))
    @insertSubView(@myMatchesTab = new MyMatchesTabView({league: @league}, @level, @sessions))
    @insertSubView(@simulateTab = new SimulateTabView(league: @league, level: @level, leagueID: @leagueID))
    highLoad = true
    @refreshDelay = switch
      when not application.isProduction() then 10  # Refresh very quickly in develompent.
      when @league then 20                         # Refresh quickly when looking at a league ladder.
      when not highLoad then 30                    # Refresh slowly when in production.
      when not me.isAnonymous() then 60            # Refresh even more slowly during HoC scaling.
      else 300                                     # Refresh super slowly if anonymous during HoC scaling.
    @refreshInterval = setInterval(@fetchSessionsAndRefreshViews.bind(@), @refreshDelay * 1000)
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
    @myMatchesTab.refreshMatches @refreshDelay
    @simulateTab.refresh()

  onIdleChanged: (e) ->
    @fetchSessionsAndRefreshViews() unless e.idle

  onClickPlayButton: (e) ->
    @showPlayModal($(e.target).closest('.play-button').data('team'))

  onClickSpectateButton: (e) ->
    humanSession = @ladderTab.spectateTargets?.humans
    ogreSession = @ladderTab.spectateTargets?.ogres
    return unless humanSession and ogreSession
    e.preventDefault()
    e.stopImmediatePropagation()
    url = "/play/spectate/#{@level.get('slug')}?session-one=#{humanSession}&session-two=#{ogreSession}"
    url += '&league=' + @league.id if @league
    url += '&autoplay=false' if key.command
    window.open url, if key.command then '_blank' else 'spectate'  # New tab for spectating specific matches
    #Backbone.Mediator.publish 'router:navigate', route: url

  showPlayModal: (teamID) ->
    session = (s for s in @sessions.models when s.get('team') is teamID)[0]
    modal = new LadderPlayModal({league: @league}, @level, session, teamID)
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
