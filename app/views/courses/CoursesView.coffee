RootView = require 'views/core/RootView'
template = require 'templates/courses/courses'
CocoCollection = require 'collections/CocoCollection'
Course = require 'models/Course'

module.exports = class CoursesView extends RootView
  id: 'courses-view'
  template: template

  constructor: (options) ->
    super options
    @courses = new CocoCollection([], { url: "/db/course", model: Course})
    @supermodel.loadCollection(@courses, 'courses')

  getRenderData: ->
    context = super()
    context.courses = @courses.models ? []
    context
