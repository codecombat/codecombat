require('app/styles/play/tournament_home.sass')
RootView = require 'views/core/RootView'
template = require 'templates/play/tournament_home'
LevelSession = require 'models/LevelSession'
Level = require 'models/Level'
Tournament = require 'models/Tournament'
forms = require 'core/forms'
CocoCollection = require 'collections/CocoCollection'

HTML5_FMT_DATETIME_LOCAL = 'YYYY-MM-DDTHH:mm' # moment 1.20+ do have this string but we use 1.19 :joy:
class LevelSessionsCollection extends CocoCollection
  url: ''
  model: LevelSession

  constructor: (model) ->
    super()
    @url = "/db/user/#{me.id}/level.sessions?project=state.complete,levelID"

class LadderCollection extends CocoCollection
  url: ''
  model: Level

  constructor: (model) ->
    super()
    @url = "/db/level/-/arenas"


module.exports = class MainLadderView extends RootView
  id: 'main-ladder-view'
  template: template

  events:
    'click .create-button': 'onCreateTournament'
    'click .input-submit': 'onSubmitEditing'

  initialize: (options, @clanId)->
    super()
    @levelStatusMap = []
    @levelPlayCountMap = []
    @campaigns = campaigns
    @tournaments = []
    tournaments = new CocoCollection([], {url: "/db/tournaments?clanId=#{@clanId}", model: Tournament})
    @listenTo tournaments, 'sync', =>
      @tournaments = (t.toJSON() for t in tournaments.models)
      @render?()
    @supermodel.loadCollection(tournaments, 'tournaments', {cache: false})

    @editableTournament = {}

    @sessions = @supermodel.loadCollection(new LevelSessionsCollection(), 'your_sessions', {cache: false}, 0).model
    @ladders = @supermodel.loadCollection(new LadderCollection()).model
    @listenToOnce @sessions, 'sync', @onSessionsLoaded
    @listenToOnce @ladders, 'sync', @onLaddersLoaded

    # TODO: Make sure this is also enabled server side.
    # Disabled due to high load on database.
    # @getLevelPlayCounts()

  getMeta: ->
    title: $.i18n.t 'ladder.title'

  onSubmitEditing: (e) ->
    attrs = forms.formToObject($(e.target).closest('.editable-tournament-form'))
    attrs.startDate = moment(attrs.startDate).toISOString()
    attrs.endDate = moment(attrs.endDate).toISOString()
    Object.assign(@editableTournament, attrs)
    if @editableTournament.editing is 'new'
      $.ajax({
        method: 'POST'
        url: '/db/tournament'
        data: @editableTournament
        success: =>
          # document.location.reload()
      })
    else if @editableTournament.editing is 'edit'
      $.ajax({
        method: 'PUT'
        url: "/db/tournament/#{@editableTournament._id}"
        data: @editableTournament
        success: =>
          # document.lodaction.reload()
      })
  onCreateTournament: (e) ->
    level = $(e.target).data('level')
    if @editableTournament.levelOriginal?
      # TODO alert do not create multiple tournament at the same time
      return
    @editableTournament = {
      name: level.name,
      levelOriginal: level.original,
      slug: level.id
      clan: @clanId,
      startDate: new Date(),
      endDate: undefined,
      editing: 'new'
    }
    @tournaments.push(@editableTournament)
    @renderSelectors('.tournament-container')

  onSessionsLoaded: (e) ->
    for session in @sessions.models
      @levelStatusMap[session.get('levelID')] = if session.get('state')?.complete then 'complete' else 'started'
    @render()

  onLaddersLoaded: (e) ->
    levels = []
    for ladder in @ladders.models
      levels.push({
        name: ladder.get('name'),
        difficulty: 1,
        id: ladder.get('slug'),
        original: ladder.get('original')
      })
    @campaigns[0].levels = levels

  getLevelPlayCounts: ->
    success = (levelPlayCounts) =>
      return if @destroyed
      for level in levelPlayCounts
        @levelPlayCountMap[level._id] = playtime: level.playtime, sessions: level.sessions
      @render() if @supermodel.finished()

    levelIDs = []
    for campaign in campaigns
      for level in campaign.levels
        levelIDs.push level.id
    levelPlayCountsRequest = @supermodel.addRequestResource 'play_counts', {
      url: '/db/level/-/play_counts'
      data: {ids: levelIDs}
      method: 'POST'
      success: success
    }, 0
    levelPlayCountsRequest.load()

  formatTime: (time) ->
    if time?
      return moment(time).format(HTML5_FMT_DATETIME_LOCAL)
    return time

ladders = [
  {
    name: 'Counter Attack'
    difficulty: 3
    id: 'counter-attack'
    image: '/file/db/level/550363b4ec31df9c691ab629/MAR26-Banner_Zero%20Sum.png'
    description: 'a test ladder'
  }
]

tournaments = [
]
campaigns = [
  {id: 'multiplayer', name: 'Multiplayer Arenas', description: '... in which you code head-to-head against other players.', levels: ladders}
]
