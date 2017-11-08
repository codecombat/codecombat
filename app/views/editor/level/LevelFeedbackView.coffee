require('app/styles/editor/level/level-feedback-view.sass')
CocoView = require 'views/core/CocoView'
CocoCollection = require 'collections/CocoCollection'
template = require 'templates/editor/level/level-feedback-view'
Level = require 'models/Level'
LevelFeedback = require 'models/LevelFeedback'

class LevelFeedbackCollection extends CocoCollection
  model: LevelFeedback
  initialize: (models, options) ->
    super models, options
    @url = "/db/level/#{options.level.get('slug')}/all_feedback"

  comparator: (a, b) ->
    score = 0
    score -= 9001900190019001 if a.get('creator') is me.id
    score += 9001900190019001 if b.get('creator') is me.id
    score -= new Date(a.get 'created')
    score -= -(new Date(b.get 'created'))
    score -= 900190019001 if a.get('review')
    score += 900190019001 if b.get('review')
    if score < 0 then -1 else (if score > 0 then 1 else 0)

module.exports = class LevelFeedbackView extends CocoView
  id: 'level-feedback-view'
  template: template
  className: 'tab-pane'

  subscriptions:
    'editor:view-switched': 'onViewSwitched'

  constructor: (options) ->
    super options

  getRenderData: (context={}) ->
    context = super(context)
    context.moment = moment
    context.allFeedback = []
    context.averageRating = 0
    context.totalRatings = 0
    if @allFeedback?.models.length
      context.allFeedback = (m.attributes for m in @allFeedback.models when @allFeedback.models.length < 20 or m.get('review'))
      context.averageRating = _.reduce((m.get('rating') for m in @allFeedback.models), (acc, x) -> acc + (x ? 5)) / (@allFeedback.models.length)
      context.totalRatings = @allFeedback.models.length
    else
      context.loading = true
    context

  onViewSwitched: (e) ->
    # Lazily load.
    return unless e.targetURL is '#level-feedback-view'
    unless @allFeedback
      @allFeedback = @supermodel.loadCollection(new LevelFeedbackCollection(null, level: @options.level), 'feedback').model
      @render()
