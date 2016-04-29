RootView = require 'views/core/RootView'
template = require 'templates/artisans/courseGearView'
Level = require 'models/Level'
Campaign = require 'models/Campaign'
Level = require 'models/Level'
CocoCollection = require 'collections/CocoCollection'

module.exports = class CourseGearView extends RootView
  template: template
  id: 'course-gear-view'
  initialize: ->
    @campaigns = new CocoCollection([],
      url: '/db/campaign?project=slug'
      model: Campaign
    )
    @supermodel.trackRequest(@campaigns.fetch())