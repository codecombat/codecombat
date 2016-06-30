RootView = require 'views/core/RootView'
CocoCollection = require 'collections/CocoCollection'
Campaigns = require 'collections/Campaigns'
Course = require 'models/Course'

module.exports = class AdminClassroomLevelsView extends RootView
  id: 'admin-classroom-levels-view'
  template: require 'templates/admin/admin-classroom-levels'

  initialize: ->
    return super() unless me.isAdmin()
    @campaigns = new Campaigns()
    @supermodel.trackRequest @campaigns.fetchByType('course', { data: { project: 'levels,levelsUpdated' } })
    @courses = new CocoCollection([], { url: "/db/course", model: Course})
    @supermodel.loadCollection(@courses, 'courses')
    super()
