CocoView = require 'views/core/CocoView'
utils = require 'core/utils'
urls = require 'core/urls'

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
    if @level.get('shareable') is 'project'
      @shareURL = urls.playDevLevel({@level, @session, @course})

  onClickDoneButton: ->
    @trigger 'done'

  onClickNextLevelButton: ->
    @trigger 'next-level'

  onClickLadderButton: ->
    @trigger 'ladder'

  onClickShareLevelButton: ->
    if _.string.startsWith(@course.get('slug'), 'game-dev')
      name = 'Student Game Dev - Copy URL'
      category = 'GameDev'
    else
      name = 'Student Web Dev - Copy URL'
      category = 'WebDev'
    eventProperties = {
      levelID: @level.id
      levelSlug: @level.get('slug')
      classroomID: @classroom.id
      courseID: @course.id
      category
    }
    window.tracker?.trackEvent name, eventProperties, ['MixPanel']
    @$('#share-level-input').val(@shareURL).select()
    @tryCopy()
