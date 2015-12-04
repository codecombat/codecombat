ModalView = require 'views/core/ModalView'
template = require 'templates/play/ladder/play_modal'
ThangType = require 'models/ThangType'
{me} = require 'core/auth'
LeaderboardCollection = require 'collections/LeaderboardCollection'
{teamDataFromLevel} = require './utils'

module.exports = class LadderPlayModal extends ModalView
  id: 'ladder-play-modal'
  template: template
  closeButton: true
  @shownTutorialButton: false
  tutorialLevelExists: null

  events:
    'click #skip-tutorial-button': 'hideTutorialButtons'
    'change #tome-language': 'updateLanguage'

  defaultAceConfig:
    language: 'javascript'
    keyBindings: 'default'
    invisibles: false
    indentGuides: false
    behaviors: false
    liveCompletion: true

  constructor: (options, @level, @session, @team) ->
    super(options)
    @nameMap = {}
    @otherTeam = if @team is 'ogres' then 'humans' else 'ogres'
    @startLoadingChallengersMaybe()
    @wizardType = ThangType.loadUniversalWizard()

  updateLanguage: ->
    aceConfig = _.cloneDeep me.get('aceConfig') ? {}
    aceConfig = _.defaults aceConfig, @defaultAceConfig
    aceConfig.language = @$el.find('#tome-language').val()
    me.set 'aceConfig', aceConfig
    me.patch()
    if @session
      @session.set 'codeLanguage', aceConfig.language
      @session.patch()

  # PART 1: Load challengers from the db unless some are in the matches
  startLoadingChallengersMaybe: ->
    if @options.league
      matches = _.find(@session?.get('leagues'), leagueID: @options.league.id)?.stats.matches
    else
      matches = @session?.get('matches')
    if matches?.length then @loadNames() else @loadChallengers()

  loadChallengers: ->
    @challengersCollection = new ChallengersData(@level, @team, @otherTeam, @session, @options.league)
    @listenTo(@challengersCollection, 'sync', @loadNames)

  # PART 2: Loading the names of the other users

  loadNames: ->
    @challengers = @getChallengers()
    ids = (challenger.opponentID for challenger in _.values @challengers)

    success = (@nameMap) =>
      for challenger in _.values(@challengers)
        challenger.opponentName = @nameMap[challenger.opponentID]?.name or 'Anoner'
        challenger.opponentWizard = @nameMap[challenger.opponentID]?.wizard or {}
      @checkWizardLoaded()

    userNamesRequest = @supermodel.addRequestResource 'user_names', {
      url: '/db/user/-/names'
      data: {ids: ids, wizard: true}
      method: 'POST'
      success: success
    }, 0
    userNamesRequest.load()

  # PART 3: Make sure wizard is loaded

  checkWizardLoaded: ->
    if @wizardType.loaded then @finishRendering() else @listenToOnce(@wizardType, 'sync', @finishRendering)

  # PART 4: Render

  finishRendering: ->
    return if @destroyed
    @checkTutorialLevelExists (exists) =>
      @tutorialLevelExists = exists
      @render()
      @maybeShowTutorialButtons()

  getRenderData: ->
    ctx = super()
    ctx.level = @level
    ctx.levelID = @level.get('slug') or @level.id
    ctx.teamName = _.string.titleize @team
    ctx.teamID = @team
    ctx.otherTeamID = @otherTeam
    ctx.tutorialLevelExists = @tutorialLevelExists
    ctx.language = @session?.get('codeLanguage') ? me.get('aceConfig')?.language ? 'python'
    ctx.languages = [
      {id: 'python', name: 'Python'}
      {id: 'javascript', name: 'JavaScript'}
      {id: 'coffeescript', name: 'CoffeeScript (Experimental)'}
      {id: 'clojure', name: 'Clojure (Experimental)'}
      {id: 'lua', name: 'Lua'}
      #{id: 'io', name: 'Io (Experimental)'}
    ]
    ctx.league = @options.league
    teamsList = teamDataFromLevel @level
    teams = {}
    teams[team.id] = team for team in teamsList
    ctx.teamColor = teams[@team].primaryColor
    ctx.teamBackgroundColor = teams[@team].bgColor
    ctx.opponentTeamColor = teams[@otherTeam].primaryColor
    ctx.opponentTeamBackgroundColor = teams[@otherTeam].bgColor

    ctx.challengers = @challengers or {}
    for challenger in _.values ctx.challengers
      continue unless challenger and @wizardType.loaded
      if (not challenger.opponentImageSource) and challenger.opponentWizard?.colorConfig
        challenger.opponentImageSource = @wizardType.getPortraitSource(
          {colorConfig: challenger.opponentWizard.colorConfig})

    if @wizardType.loaded
      ctx.genericPortrait = @wizardType.getPortraitSource()
      myColorConfig = me.get('wizard')?.colorConfig
      ctx.myPortrait = if myColorConfig then @wizardType.getPortraitSource({colorConfig: myColorConfig}) else ctx.genericPortrait

    ctx.myName = me.get('name') || 'Newcomer'
    ctx

  maybeShowTutorialButtons: ->
    return if @session or LadderPlayModal.shownTutorialButton or not @tutorialLevelExists
    @$el.find('#normal-view').addClass('secret')
    @$el.find('.modal-header').addClass('secret')
    @$el.find('#noob-view').removeClass('secret')
    LadderPlayModal.shownTutorialButton = true

  hideTutorialButtons: ->
    @$el.find('#normal-view').removeClass('secret')
    @$el.find('.modal-header').removeClass('secret')
    @$el.find('#noob-view').addClass('secret')

  checkTutorialLevelExists: (cb) ->
    levelID = @level.get('slug') or @level.id
    tutorialLevelID = "#{levelID}-tutorial"
    success = => cb true
    failure = => cb false
    $.ajax
      type: 'GET'
      url: "/db/level/#{tutorialLevelID}/exists"
      success: success
      error: failure

  # Choosing challengers

  getChallengers: ->
    # make an object of challengers to everything needed to link to them
    challengers = {}
    if @challengersCollection
      easyInfo = @challengeInfoFromSession(@challengersCollection.easyPlayer.models[0])
      mediumInfo = @challengeInfoFromSession(@challengersCollection.mediumPlayer.models[0])
      hardInfo = @challengeInfoFromSession(@challengersCollection.hardPlayer.models[0])
    else
      if @options.league
        matches = _.find(@session?.get('leagues'), leagueID: @options.league.id)?.stats.matches
      else
        matches = @session?.get('matches')
      won = (m for m in matches when m.metrics.rank < m.opponents[0].metrics.rank)
      lost = (m for m in matches when m.metrics.rank > m.opponents[0].metrics.rank)
      tied = (m for m in matches when m.metrics.rank is m.opponents[0].metrics.rank)
      easyInfo = @challengeInfoFromMatches(won)
      mediumInfo = @challengeInfoFromMatches(tied)
      hardInfo = @challengeInfoFromMatches(lost)
    @addChallenger easyInfo, challengers, 'easy'
    @addChallenger mediumInfo, challengers, 'medium'
    @addChallenger hardInfo, challengers, 'hard'
    challengers

  addChallenger: (info, challengers, title) ->
    # check for duplicates first
    return unless info
    for key, value of challengers
      return if value.sessionID is info.sessionID
    challengers[title] = info

  challengeInfoFromSession: (session) ->
    # given a model from the db, return info needed for a link to the match
    return unless session
    return {
      sessionID: session.id
      opponentID: session.get 'creator'
      codeLanguage: session.get 'submittedCodeLanguage'
    }

  challengeInfoFromMatches: (matches) ->
    return unless matches?.length
    match = _.sample matches
    opponent = match.opponents[0]
    return {
      sessionID: opponent.sessionID
      opponentID: opponent.userID
      codeLanguage: opponent.codeLanguage
    }

class ChallengersData
  constructor: (@level, @team, @otherTeam, @session, @league) ->
    _.extend @, Backbone.Events
    if @league
      score = _.find(@session?.get('leagues'), leagueID: @league.id)?.stats?.totalScore or 10
    else
      score = @session?.get('totalScore') or 10
    for player in [
      {type: 'easyPlayer', order: 1, scoreOffset: score - 5}
      {type: 'mediumPlayer', order: 1, scoreOffset: score}
      {type: 'hardPlayer', order: -1, scoreOffset: score + 5}
    ]
      playerResource = @[player.type] = new LeaderboardCollection(@level, @collectionParameters(order: player.order, scoreOffset: player.scoreOffset))
      playerResource.fetch cache: false
      @listenToOnce playerResource, 'sync', @challengerLoaded

  collectionParameters: (parameters) ->
    parameters.team = @otherTeam
    parameters.limit = 1
    parameters['leagues.leagueID'] = @league.id if @league
    parameters

  challengerLoaded: ->
    if @allLoaded()
      @loaded = true
      @trigger 'sync'

  playerIDs: ->
    collections = [@easyPlayer, @mediumPlayer, @hardPlayer]
    (c.models[0].get('creator') for c in collections when c?.models[0])

  allLoaded: ->
    _.all [@easyPlayer.loaded, @mediumPlayer.loaded, @hardPlayer.loaded]
