app = require 'core/application'
RootView = require 'views/core/RootView'
template = require 'templates/courses/mock1/course-details'

module.exports = class CourseDetailsView extends RootView
  id: 'course-details-view'
  template: template

  events:
    'change .expand-progress-checkbox': 'onExpandedProgressCheckbox'
    'change .select-session': 'onChangeSession'
    'click .edit-class-name-btn': 'onClickEditClassName'
    'click .edit-description-btn': 'onClickEditClassDescription'

  constructor: (options, @courseID) ->
    super options
    @initData()

  getRenderData: ->
    context = super()
    context.course = @course ? {}
    context.instance = @instances?[@currentInstanceIndex] ? {}
    context.instances = @instances ? []
    context.maxLastStartedIndex = @maxLastStartedIndex ? 0
    context.userLevelStateMap = @userLevelStateMap ? {}
    context.showExpandedProgress = @maxLastStartedIndex <= 30 or @showExpandedProgress
    context

  initData: ->
    mockData = require 'views/courses/mock1/CoursesMockData'
    @course = mockData.courses[@courseID]
    @currentInstanceIndex = 0
    @instances = mockData.instances
    @updateLevelMaps()

  updateLevelMaps: ->
    @userLevelStateMap = {}
    @maxLastStartedIndex = -1
    for student in @instances?[@currentInstanceIndex].students
      lastCompletedIndex = _.random(0, @course.levels.length)
      lastStartedIndex = lastCompletedIndex + 1
      @userLevelStateMap[student] =
        lastCompletedIndex: lastCompletedIndex
        lastStartedIndex: lastStartedIndex
      @maxLastStartedIndex = lastStartedIndex if lastStartedIndex > @maxLastStartedIndex

  onChangeSession: (e) ->
    @showExpandedProgress = false
    newSessionValue = $(e.target).val()
    @currentInstanceIndex = index for val, index in @instances when val.name is newSessionValue
    @updateLevelMaps()
    @render?()

  onExpandedProgressCheckbox: (e) ->
    @showExpandedProgress = $('.expand-progress-checkbox').prop('checked')
    # TODO: why does render reset the checkbox to be unchecked?
    @render?()
    $('.expand-progress-checkbox').attr('checked', @showExpandedProgress)

  onClickEditClassName: (e) ->
    alert 'TODO: Popup for editing name for this course session'

  onClickEditClassDescription: (e) ->
    alert 'TODO: Popup for editing description for this course session'
