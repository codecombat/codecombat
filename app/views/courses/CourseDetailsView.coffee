RootView = require 'views/core/RootView'
template = require 'templates/courses/course-details'
CocoCollection = require 'collections/CocoCollection'
Course = require 'models/Course'
CourseInstance = require 'models/CourseInstance'

# TODO: logged out experience
# TODO: no course instances
# TODO: no course instance selected

module.exports = class CourseDetailsView extends RootView
  id: 'course-details-view'
  template: template

  constructor: (options, @courseID) ->
    super options
    @courseInstanceID = options.courseInstanceID
    @course = new Course _id: @courseID
    @supermodel.loadModel @course, 'course', cache: false
    if @courseInstanceID
      @courseInstance = new CourseInstance _id: @courseInstanceID
      @supermodel.loadModel @courseInstance, 'course_instance', cache: false
    else if !me.isAnonymous()
      @courseInstances = new CocoCollection([], { url: "/db/user/#{me.id}/course_instances", model: CourseInstance})
      @listenToOnce @courseInstances, 'sync', @onCourseInstancesLoaded
      @supermodel.loadCollection(@courseInstances, 'course_instances')

  getRenderData: ->
    context = super()
    context.course = @course
    context.courseInstance = @courseInstance
    context

  onCourseInstancesLoaded: ->
    if @courseInstances.models.length is 1
      @courseInstance = @courseInstances.models[0]
    else if @courseInstances.models.length > 0
      @courseInstance = @courseInstances.models[0]
