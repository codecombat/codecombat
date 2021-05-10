require('app/styles/play/ladder/ladder.sass')
RootView = require 'views/core/RootView'
Level = require 'models/Level'
LevelSession = require 'models/LevelSession'
CocoCollection = require 'collections/CocoCollection'
{teamDataFromLevel} = require './utils'
{me} = require 'core/auth'
# application = require 'core/application'
co = require 'co'
utils = require 'core/utils'

LadderTabView = require './LadderTabView'
MyMatchesTabView = require './MyMatchesTabView'
SimulateTabView = require './SimulateTabView'
LadderPlayModal = require './LadderPlayModal'
CocoClass = require 'core/CocoClass'

Clan = require 'models/Clan'
CourseInstance = require 'models/CourseInstance'
Course = require 'models/Course'
Mandate = require 'models/Mandate'
Tournament = require 'models/Tournament'

HIGHEST_SCORE = 1000000

STOP_CHECK_TOURNAMENT_CLOSE = 0  # tournament ended
KEEP_CHECK_TOURNAMENT_CLOSE = 1  # tournament not begin
STOP_CHECK_TOURNAMENT_OPEN = 2  # none tournament only level
KEEP_CHECK_TOURNAMENT_OPEN = 3  # tournament running

TOURNAMENT_OPEN = [2, 3]
STOP_CHECK_TOURNAMENT = [0, 2]

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
    'click .simulate-all-button': 'onClickSimulateAllButton'

  initialize: (options, @levelID, @leagueType, @leagueID) ->
    super(options)

    @level = @supermodel.loadModel(new Level(_id: @levelID)).model
    @level.once 'sync', (level) =>
      @setMeta({ title: $.i18n.t 'ladder.arena_title', { arena: level.get('name') } })

    onLoaded = =>
      return if @destroyed
      @levelDescription = marked(utils.i18n(@level.attributes, 'description')) if @level.get('description')
      @teams = teamDataFromLevel @level

    if @level.loaded then onLoaded() else @level.once('sync', onLoaded)
    @sessions = @supermodel.loadCollection(new LevelSessionsCollection(@levelID), 'your_sessions', {cache: false}).model
    @winners = require('./tournament_results')[@levelID]

    if tournamentEndDate = {greed: 1402444800000, 'criss-cross': 1410912000000, 'zero-sum': 1428364800000, 'ace-of-coders': 1444867200000, 'battle-of-red-cliffs': 1598918400000}[@levelID]
      @tournamentTimeLeft = moment(new Date(tournamentEndDate)).fromNow()
    if tournamentStartDate = {'zero-sum': 1427472000000, 'ace-of-coders': 1442417400000, 'battle-of-red-cliffs': 1596295800000}[@levelID]
      @tournamentTimeElapsed = moment(new Date(tournamentStartDate)).fromNow()

    @calcTimeOffset()
    @mandate = @supermodel.loadModel(new Mandate()).model

    @loadLeague()
    @urls = require('core/urls')

    if @tournamentId
      @checkTournamentCloseInterval = setInterval @checkTournamentClose.bind(@), 3000
    if features.china
      @checkTournamentEndInterval = setInterval @checkTournamentEnd.bind(@), 3000

  calcTimeOffset: ->
    $.ajax
      type: 'HEAD'
      success: (result, status, xhr) =>
        @timeOffset = new Date(xhr.getResponseHeader("Date")).getTime() - Date.now()

  checkTournamentEnd: ->
    return unless @timeOffset
    return unless @mandate.loaded
    return unless @level.loaded
    return if (@leagueID and not @league.loaded)
    mandate = @mandate.get('0')

    tournamentState = STOP_CHECK_TOURNAMENT_OPEN

    if mandate
      tournamentState = @getTournamentState mandate, @courseInstance?.id, @level.get('slug'), @timeOffset
      if tournamentState in TOURNAMENT_OPEN
        if @tournamentEnd
          @tournamentEnd = false
          @render()
      else
        unless @tournamentEnd or me.isAdmin()
          @tournamentEnd = true
          @render()
    if tournamentState in STOP_CHECK_TOURNAMENT
      clearInterval @checkTournamentEndInterval

  getTournamentState: (mandate, courseInstanceID, levelSlug, timeOffset) ->
    tournament = _.find mandate.currentTournament or [], (t) ->
      t.courseInstanceID is courseInstanceID and t.level is levelSlug
    if tournament
      currentTime = (Date.now() + timeOffset) / 1000
      console.log "Current time:", new Date(currentTime * 1000)
      if currentTime < tournament.startAt
        delta = tournament.startAt - currentTime
        console.log "Tournament will start at: #{new Date(tournament.startAt * 1000)}, Time left: #{parseInt(delta / 60 / 60) }:#{parseInt(delta / 60) % 60}:#{parseInt(delta) % 60}"
        return KEEP_CHECK_TOURNAMENT_CLOSE
      else if currentTime > tournament.endAt
        console.log "Tournament ended at: #{new Date(tournament.endAt * 1000)}"
        return STOP_CHECK_TOURNAMENT_CLOSE
      delta = tournament.endAt - currentTime
      console.log "Tournament will end at: #{new Date(tournament.endAt * 1000)}, Time left: #{parseInt(delta / 60 / 60) }:#{parseInt(delta / 60) % 60}:#{parseInt(delta) % 60}"
      return KEEP_CHECK_TOURNAMENT_OPEN
    else
      return if levelSlug in (mandate.tournamentOnlyLevels or []) then STOP_CHECK_TOURNAMENT_CLOSE else STOP_CHECK_TOURNAMENT_OPEN

  getMeta: ->
    title: $.i18n.t 'ladder.title'
    link: [
      { vmid: 'rel-canonical', rel: 'canonical', content: '/play' }
    ]

  loadLeague: ->
    @leagueID = @leagueType = null unless @leagueType in ['clan', 'course']
    return unless @leagueID

    if @leagueType is 'clan'
      @tournamentId = utils.getQueryVariable 'tournament'

    modelClass = if @leagueType is 'clan' then Clan else CourseInstance
    @league = @supermodel.loadModel(new modelClass(_id: @leagueID)).model
    if @leagueType is 'course'
      if @league.loaded
        @onCourseInstanceLoaded @league
      else
        @listenToOnce @league, 'sync', @onCourseInstanceLoaded

  checkTournamentClose: () ->
    return unless @tournamentId?
    $.ajax
      url: "/db/tournament/#{@tournamentId}/state"
      success: (res) =>
        if res.state is 'starting'
          @tournamentEnd = false
          @tournamentState = 'starting'
        else
          @tournamentEnd = true
          if res.state is 'ended' and @tournamentState != 'ended'
            clearInterval @checkTournamentCloseInterval
            @tournamentState = 'ended'
            @render()



  onCourseInstanceLoaded: co.wrap (@courseInstance) ->
    return if @destroyed
    @classroomID = @courseInstance.get('classroomID')
    @ownerID = @courseInstance.get('ownerID')
    @isSchoolAdmin = yield me.isSchoolAdminOf({ classroomId: @classroomID })
    @isTeacher = yield me.isTeacherOf({ classroomId: @classroomID })
    course = new Course({_id: @courseInstance.get('courseID')})
    @course = @supermodel.loadModel(course).model
    @listenToOnce @course, 'sync', @render

  afterRender: ->
    super()
    return unless @supermodel.finished()
    @$el.toggleClass 'single-ladder', @level.isType 'ladder'
    unless @tournamentState is 'ended'
      @insertSubView(@ladderTab = new LadderTabView({league: @league, tournament: @tournamentId}, @level, @sessions))
      @insertSubView(@myMatchesTab = new MyMatchesTabView({league: @league}, @level, @sessions))
    else
      # @removeSubView(@ladderTab)
      # @removeSubView(@myMatchesTab)
      @insertSubView(@ladderTab = new LadderTabView({league: @league, tournament: @tournamentId}, @level, @sessions, @tournamentId))
    unless @level.isType('ladder') and me.isAnonymous()
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
    if @myMatchesTab?.refreshMatches?
      @myMatchesTab.refreshMatches @refreshDelay
    @simulateTab?.refresh()

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
    url += '&tournament=' + @tournamentId if @tournamentState is 'ended'
    window.open url, if key.command then '_blank' else 'spectate'  # New tab for spectating specific matches
    #Backbone.Mediator.publish 'router:navigate', route: url

  onClickSimulateAllButton: (e) ->
    if @tournamentId
      if key.shift
        # TODO: make this configurable
        options =
          sessionLimit: 50000
          matchLimit: 1e6
          matchmakingType: 'king-of-the-hill'
          minPlayerMatches: 20
          topN: 10
      else
        options = sessionLimit: 500
      $.ajax
        url: "/db/tournament/#{@tournamentId}/end"
        data: options
        type: 'POST'
        success: (res) ->
          console.log res
        error: (err) ->
          alert('tournament end failed')
    else
      $.ajax
        url: '/queue/scoring/loadTournamentSimulationTasks'
        data:
          originalLevelID: @level.get('original'),
          levelMajorVersion: 0,
          leagueID: @leagueID
          mirrorMatch: @level.get('mirrorMatch') ? false
          sessionLimit: 750
        type: 'POST'
        parse: true
        success: (res)->
          console.log res
        error: (err) ->
          console.error err

  showPlayModal: (teamID) ->
    session = (s for s in @sessions.models when s.get('team') is teamID)[0]
    modal = new LadderPlayModal({league: @league, tournament: @tournamentId}, @level, session, teamID)
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
    if @checkTournamentEndInterval
      clearInterval @checkTournamentEndInterval
    super()
