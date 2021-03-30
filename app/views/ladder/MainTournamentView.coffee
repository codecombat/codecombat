require('app/styles/play/tournament_home.sass')
RootView = require 'views/core/RootView'
template = require 'templates/play/tournament_home'
LevelSession = require 'models/LevelSession'
Level = require 'models/Level'
Clan = require 'models/Clan'
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
    'click .create-button': 'createTournament'
    'click .edit-button': 'editTournament'
    'click .input-submit': 'submitEditing'
    'click .input-cancel': 'cancelEditing'

  initialize: (options, @pageType, @objectId)->
    super()
    @ladderLevels = []
    @ladderImageMap = {}
    @tournaments = []

    if @pageType == 'clan'
      url = "/db/tournaments?clanId=#{@objectId}"
      @clan = @supermodel.loadModel(new Clan(_id: @objectId)).model
      @clan.once 'sync', (clan) =>
        console.log(clan, @clan)
        @renderSelectors('#ladder-list')
    else if @pageType == 'student'
      url = "/db/tournaments?memberId=#{@objectId}"
    tournaments = new CocoCollection([], {url, model: Tournament})
    @listenTo tournaments, 'sync', =>
      @tournaments = (t.toJSON() for t in tournaments.models)[0]
      @render?()
    @supermodel.loadCollection(tournaments, 'tournaments', {cache: false})

    @editableTournament = {}

    @ladders = @supermodel.loadCollection(new LadderCollection()).model
    @listenToOnce @ladders, 'sync', @onLaddersLoaded

  getMeta: ->
    title: $.i18n.t 'ladder.title'

  cancelEditing: (e) ->
    if @editableTournament.editing is 'new'
      @tournaments[@clan.get('name')].pop()
    else
      index = _.findIndex(@tournaments[@clan.get('name')], (t) => t.editing == 'edit')
      delete @tournaments[@clan.get('name')][index].editing
    @editableTournament = {}
    @renderSelectors('.tournament-container')

  submitEditing: (e) ->
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
          document.location.reload()
      })
    else if @editableTournament.editing is 'edit'
      $.ajax({
        method: 'PUT'
        url: "/db/tournament/#{@editableTournament._id}"
        data: @editableTournament
        success: =>
          document.location.reload()
      })

  editTournament: (e) ->
    tournament = $(e.target).data('tournament')
    if @editableTournament.levelOriginal?
      return

    index = _.findIndex(@tournaments[@clan.get('name')], (t) => t._id == tournament._id)
    @tournaments[@clan.get('name')][index].editing = 'edit'
    @editableTournament = @tournaments[@clan.get('name')][index]
    @renderSelectors('.tournament-container')

  createTournament: (e) ->
    level = $(e.target).data('level')
    if @editableTournament.levelOriginal?
      # TODO alert do not create multiple tournament at the same time
      return
    @editableTournament = {
      name: level.name,
      levelOriginal: level.original,
      image: level.image,
      slug: level.id
      clan: @objectId,
      state: 'disabled',
      startDate: new Date(),
      endDate: undefined,
      editing: 'new'
    }
    @tournaments[@clan.get('name')].push(@editableTournament)
    @renderSelectors('.tournament-container')

  onLaddersLoaded: (e) ->
    levels = []
    for ladder in @ladders.models
      levels.push({
        name: ladder.get('name'),
        id: ladder.get('slug'),
        image: ladder.get('image'),
        original: ladder.get('original')
      })
      @ladderImageMap[ladder.get('original')] = ladder.get('image')
    @ladderLevels = levels

  hasControlOfTheClan: () ->
    return me.isAdmin() || (@clan?.get('ownerID') + '' == me.get('_id') + '')

  formatTime: (time) ->
    if time?
      return moment(time).format(HTML5_FMT_DATETIME_LOCAL)
    return time
