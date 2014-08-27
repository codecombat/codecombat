ModalView = require 'views/kinds/ModalView'
template = require 'templates/play/ladder/play_modal'
ThangType = require 'models/ThangType'
{me} = require 'lib/auth'
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
    @otherTeam = if team is 'ogres' then 'humans' else 'ogres'
    @startLoadingChallengersMaybe()
    @wizardType = ThangType.loadUniversalWizard()

  updateLanguage: ->
    aceConfig = _.cloneDeep me.get('aceConfig') ? {}
    aceConfig = _.defaults aceConfig, @defaultAceConfig
    aceConfig.language = @$el.find('#tome-language').val()
    me.set 'aceConfig', aceConfig
    me.patch()

  # PART 1: Load challengers from the db unless some are in the matches
  startLoadingChallengersMaybe: ->
    matches = @session?.get('matches')
    if matches?.length then @loadNames() else @loadChallengers()

  loadChallengers: ->
    @challengersCollection = new ChallengersData(@level, @team, @otherTeam, @session)
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
    ctx.languages = [
      {id: 'javascript', name: 'JavaScript'}
      {id: 'coffeescript', name: 'CoffeeScript'}
      {id: 'python', name: 'Python (Experimental)'}
      {id: 'clojure', name: 'Clojure (Experimental)'}
      {id: 'lua', name: 'Lua (Experimental)'}
      {id: 'io', name: 'Io (Experimental)'}
    ]
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
      matches = @session.get('matches')
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
  constructor: (@level, @team, @otherTeam, @session) ->
    _.extend @, Backbone.Events
    score = @session?.get('totalScore') or 25
    @easyPlayer = new LeaderboardCollection(@level, {order: 1, scoreOffset: score - 5, limit: 1, team: @otherTeam})
    @easyPlayer.fetch()
    @listenToOnce(@easyPlayer, 'sync', @challengerLoaded)
    @mediumPlayer = new LeaderboardCollection(@level, {order: 1, scoreOffset: score, limit: 1, team: @otherTeam})
    @mediumPlayer.fetch()
    @listenToOnce(@mediumPlayer, 'sync', @challengerLoaded)
    @hardPlayer = new LeaderboardCollection(@level, {order: -1, scoreOffset: score + 5, limit: 1, team: @otherTeam})
    @hardPlayer.fetch()
    @listenToOnce(@hardPlayer, 'sync', @challengerLoaded)

  challengerLoaded: ->
    if @allLoaded()
      @loaded = true
      @trigger 'sync'

  playerIDs: ->
    collections = [@easyPlayer, @mediumPlayer, @hardPlayer]
    (c.models[0].get('creator') for c in collections when c?.models[0])

  allLoaded: ->
    _.all [@easyPlayer.loaded, @mediumPlayer.loaded, @hardPlayer.loaded]
