CocoView = require 'views/core/CocoView'
template = require 'templates/play/modal/leaderboard-tab-view'
CocoCollection = require 'collections/CocoCollection'
LevelSession = require 'models/LevelSession'
fetchJson = require 'core/api/fetch-json'

class TopScoresCollection extends CocoCollection
  url: ''
  model: LevelSession

  constructor: (@level, @scoreType, @timespan) ->
    super()
    @url = "/db/level/#{@level.get('original')}/top_scores/#{@scoreType}/#{@timespan}"

module.exports = class LeaderboardTabView extends CocoView
  template: template
  className: 'leaderboard-tab-view'

  events:
    'click tbody tr.viewable': 'onClickRow'
    'click tbody tr.viewable .nuke-button': 'onClickNukeButton'

  constructor: (options) ->
    super options
    @level = @options.level
    @scoreType = @options.scoreType ? 'time'
    @timespan = @options.timespan

  destroy: ->
    super()

  getRenderData: ->
    c = super()
    c.scoreType = @scoreType
    c.timespan = @timespan
    c.topScores = @formatTopScores()
    c.loading = not @sessions or @sessions.loading
    c._ = _
    c

  afterRender: ->
    super()
    @$('[data-toggle="tooltip"]').tooltip(placement: 'bottom', html: true, animation: false, container: '.modal-content')

  formatTopScores: ->
    return [] unless @sessions?.models
    rows = []
    for s in @sessions.models
      row = {}
      score = _.find s.get('state').topScores, type: @scoreType
      scoreDate = new Date(score.date)
      if (scoreDate - 1) > (new Date() - 1) and not me.isAdmin()
        scoreDate = new Date(new Date() - 12 * 60 * 60 * 1000)  # Make up 12 hours ago time for bogus dates in the future
      row.ago = moment(scoreDate).fromNow()
      row.score = @formatScore score
      row.creatorName = s.get 'creatorName'
      row.creator = s.get 'creator'
      row.session = s.id
      row.codeLanguage = s.get 'codeLanguage'
      row.hero = s.get('heroConfig')?.thangType
      row.inventory = s.get('heroConfig')?.inventory
      row.code = s.get('code')?['hero-placeholder']?.plan
      rows.push row
    rows

  formatScore: (score) ->
    switch score.type
      when 'time' then -score.score.toFixed(2) + 's'
      when 'damage-taken' then -Math.round score.score
      when 'damage-dealt', 'gold-collected', 'difficulty' then Math.round score.score
      else score.score

  onShown: ->
    return if @hasShown
    @hasShown = true
    topScores = new TopScoresCollection @level, @scoreType, @timespan
    @sessions = @supermodel.loadCollection(topScores, 'sessions', {cache: false}, 0).model

  onClickRow: (e) ->
    sessionID = $(e.target).closest('tr').data 'session-id'
    url = "/play/level/#{@level.get('slug')}?session=#{sessionID}&observing=true"
    window.open url, '_blank'

  onClickNukeButton: (e) ->
    e.stopImmediatePropagation()
    sessionID = $(e.target).closest('tr').data 'session-id'
    @playSound 'menu-button-click'
    fetchJson('/db/level.session/unset-scores', method: 'POST', json: {session: sessionID}).then (response) =>
      @$("tr[data-session-id=#{sessionID}]").tooltip('destroy').remove()
