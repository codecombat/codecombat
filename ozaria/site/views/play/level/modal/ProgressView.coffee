require('app/styles/play/level/modal/progress-view.sass')
CocoView = require 'views/core/CocoView'
utils = require 'core/utils'
urls = require 'core/urls'

module.exports = class ProgressView extends CocoView
  # TODO: Clean up what was moved to CourseVictoryComponent

  id: 'progress-view'
  className: 'modal-content'
  template: require 'templates/play/level/modal/progress-view'

  events:
    'click #done-btn': 'onClickDoneButton'
    'click #next-level-btn': 'onClickNextLevelButton'
    'click #start-challenge-btn': 'onClickStartChallengeButton'
    'click #map-btn': 'onClickMapButton'
    'click #ladder-btn': 'onClickLadderButton'
    'click #publish-btn': 'onClickPublishButton'
    'click #share-level-btn': 'onClickShareLevelButton'

  initialize: (options) ->
    @level = options.level
    @course = options.course
    @classroom = options.classroom #not guaranteed to exist (eg. when teacher is playing)
    @nextLevel = options.nextLevel
    @nextAssessment = options.nextAssessment
    @levelSessions = options.levelSessions
    @session = options.session
    @courseInstanceID = options.courseInstanceID
    # Translate and Markdownify level description, but take out any images (we don't have room for arena banners, etc.).
    # Images in Markdown are like ![description](url)
    @nextLevel.get('description', true)  # Make sure the defaults are available
    @nextLevelDescription = marked(utils.i18n(@nextLevel.attributesWithDefaults, 'description').replace(/!\[.*?\]\(.*?\)\n*/g, ''))
    @nextAssessment.get('description', true)  # Make sure the defaults are available
    @nextAssessmentDescription = marked(utils.i18n(@nextAssessment.attributesWithDefaults, 'description').replace(/!\[.*?\]\(.*?\)\n*/g, ''))
    if @level.isProject()
      @shareURL = urls.playDevLevel({@level, @session, @course})

  onClickDoneButton: ->
    @trigger 'done'

  onClickNextLevelButton: ->
    @trigger 'next-level'

  onClickStartChallengeButton: ->
    @trigger 'start-challenge'

  onClickPublishButton: ->
    @trigger 'publish'

  onClickMapButton: ->
    @trigger 'to-map'

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
