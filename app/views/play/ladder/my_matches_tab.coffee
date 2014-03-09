CocoView = require 'views/kinds/CocoView'
Level = require 'models/Level'
LevelSession = require 'models/LevelSession'
LeaderboardCollection  = require 'collections/LeaderboardCollection'
{teamDataFromLevel} = require './utils'

module.exports = class MyMatchesTabView extends CocoView
  id: 'my-matches-tab-view'
  template: require 'templates/play/ladder/my_matches_tab'
  startsLoading: true

  events:
    'click .rank-button': 'rankSession'

  constructor: (options, @level, @sessions) ->
    super(options)
    @nameMap = {}
    @refreshMatches()

  refreshMatches: ->
    @teams = teamDataFromLevel @level
    @loadNames()

  loadNames: ->
    # Only fetch the names for the userIDs we don't already have in @nameMap
    ids = []
    for session in @sessions.models
      for match in (session.get('matches') or [])
        id = match.opponents[0].userID
        ids.push id unless @nameMap[id]

    return @finishRendering() unless ids.length

    success = (nameMap) =>
      for session in @sessions.models
        for match in session.get('matches') or []
          opponent = match.opponents[0]
          @nameMap[opponent.userID] = nameMap[opponent.userID]
      @finishRendering()

    $.ajax('/db/user/-/names', {
      data: {ids: ids}
      type: 'POST'
      success: success
    })

  finishRendering: ->
    @startsLoading = false
    @render()

  getRenderData: ->
    ctx = super()
    ctx.level = @level
    ctx.levelID = @level.get('slug') or @level.id
    ctx.teams = @teams

    convertMatch = (match) =>
      opponent = match.opponents[0]
      state = 'win'
      state = 'loss' if match.metrics.rank > opponent.metrics.rank
      state = 'tie' if match.metrics.rank is opponent.metrics.rank
      {
        state: state
        opponentName: @nameMap[opponent.userID]
        opponentID: opponent.userID
        when: moment(match.date).fromNow()
        sessionID: opponent.sessionID
      }

    for team in @teams
      team.session = (s for s in @sessions.models when s.get('team') is team.id)[0]
      team.readyToRank = @readyToRank(team.session)
      team.matches = (convertMatch(match) for match in team.session?.get('matches') or [])
      team.matches.reverse()
      team.score = (team.session?.get('totalScore') or 10).toFixed(2)

    ctx

  afterRender: ->
    super()
    @$el.find('.rank-button').each (i, el) =>
      button = $(el)
      sessionID = button.data('session-id')
      session = _.find @sessions.models, { id: sessionID }
      @setRankingButtonText button, if @readyToRank(session) then 'rank' else 'unavailable'

  readyToRank: (session) ->
    return false unless session?.get('levelID')  # If it hasn't been denormalized, then it's not ready.
    c1 = session?.get('code')
    c2 = session?.get('submittedCode')
    c1 and not _.isEqual(c1, c2)

  rankSession: (e) ->
    console.log "Clicked"
    button = $(e.target).closest('.rank-button')
    sessionID = button.data('session-id')
    session = _.find @sessions.models, { id: sessionID }
    return unless @readyToRank(session)

    @setRankingButtonText(button, 'ranking')
    success = => @setRankingButtonText(button, 'ranked')
    failure = => @setRankingButtonText(button, 'failed')

    ajaxData = { session: sessionID, levelID: @level.id, originalLevelID: @level.attributes.original, levelMajorVersion: @level.attributes.version.major }
    $.ajax '/queue/scoring', {
      type: 'POST'
      data: ajaxData
      success: success
      failure: failure
    }

  setRankingButtonText: (rankButton, spanClass) ->
    rankButton.find('span').addClass('hidden')
    rankButton.find(".#{spanClass}").removeClass('hidden')
    rankButton.toggleClass 'disabled', spanClass isnt 'rank'
