RootView = require 'views/core/RootView'
CocoCollection = require 'collections/CocoCollection'
Campaign = require 'models/Campaign'
Course = require 'models/Course'

module.exports = class AdminClassroomLevelsView extends RootView
  id: 'admin-classroom-levels-view'
  template: require 'templates/admin/admin-classroom-levels'

  initialize: ->
    return super() unless me.isAdmin()
    @campaigns = new CocoCollection([], { url: "/db/campaign", model: Campaign})
    @supermodel.loadCollection(@campaigns, 'campaigns')
    @courses = new CocoCollection([], { url: "/db/course", model: Course})
    @supermodel.loadCollection(@courses, 'courses')
    super()
