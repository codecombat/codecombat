CocoView = require 'views/core/CocoView'
template = require 'templates/play/modal/leaderboard-tab-view'
CocoCollection = require 'collections/CocoCollection'
LevelSession = require 'models/LevelSession'

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

  formatTopScores: ->
    return [] unless @sessions?.models
    rows = []
    for s in @sessions.models
      row = {}
      score = _.find s.get('state').topScores, type: @scoreType
      row.ago = moment(new Date(score.date)).fromNow()
      row.score = @formatScore score
      row.creatorName = s.get 'creatorName'
      row.creator = s.get 'creator'
      row.session = s.id
      row.codeLanguage = s.get 'codeLanguage'
      row.hero = s.get('heroConfig')?.thangType
      row.inventory = s.get('heroConfig')?.inventory
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
