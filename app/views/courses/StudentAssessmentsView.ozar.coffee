RootComponent = require 'views/core/RootComponent'
StudentAssessmentsComponent = require('./StudentAssessmentsComponent').default

module.exports = class StudentAssessmentsView extends RootComponent
  id: 'student-assessments-view'
  template: require 'templates/base-flat'
  VueComponent: StudentAssessmentsComponent
  constructor: (options, @classroomID) ->
    @propsData = { @classroomID }
    super options
