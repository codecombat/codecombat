RootComponent = require 'views/core/RootComponent'
CourseVideosComponent = require('./CourseVideosComponent').default

module.exports = class CourseVideosView extends RootComponent
  id: 'course-videos-view'
  template: require 'templates/base-flat'
  VueComponent: CourseVideosComponent
  constructor: (options, @courseID, @courseName) ->
    @propsData = { @courseID, @courseName }
    super options
