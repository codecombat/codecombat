CocoView = require 'views/core/CocoView'
utils = require 'core/utils'

module.exports = class ProgressView extends CocoView

  id: 'progress-view'
  className: 'modal-content'
  template: require 'templates/play/level/modal/progress-view'

  events:
    'click #done-btn': 'onClickDoneButton'
    'click #next-level-btn': 'onClickNextLevelButton'
    'click #ladder-btn': 'onClickLadderButton'
    'click #share-level-btn': 'onClickShareLevelButton'

  initialize: (options) ->
    @level = options.level
    @course = options.course
    @classroom = options.classroom
    @nextLevel = options.nextLevel
    @levelSessions = options.levelSessions
    @session = options.session
    # Translate and Markdownify level description, but take out any images (we don't have room for arena banners, etc.).
    # Images in Markdown are like ![description](url)
    @nextLevel.get('description', true)  # Make sure the defaults are available
    @nextLevelDescription = marked(utils.i18n(@nextLevel.attributesWithDefaults, 'description').replace(/!\[.*?\]\(.*?\)\n*/g, ''))
    if @level.isType('game-dev', 'web-dev')
      @shareURL = "#{window.location.origin}/play/#{@level.get('type')}-level/#{@level.get('slug')}/#{@session.id}"
      @shareURL += "?course=#{@course.id}" if @course

  onClickDoneButton: ->
    @trigger 'done'

  onClickNextLevelButton: ->
    @trigger 'next-level'

  onClickLadderButton: ->
    @trigger 'ladder'

  onClickShareLevelButton: ->
    @$('#share-level-input').val(@shareURL).select()
    @tryCopy()
