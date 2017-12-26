require('app/styles/admin/admin-classroom-levels.sass')
RootView = require 'views/core/RootView'
RootComponent = require 'views/core/RootComponent'
template = require 'templates/base-flat'
co = require('co')
api = require 'core/api'
Campaign = require 'models/Campaign'

AdminClassroomLevelsComponent = Vue.extend
  template: require('templates/admin/admin-classroom-levels')()

  data: ->
    campaigns: []
    courses: []
    loading: true

  created: co.wrap ->
    return unless @loading
    yield Promise.all([
      api.campaigns.getAll().then((@campaigns) =>)
      api.courses.getAll().then((@courses) =>)
    ]).then =>
      @loading = false

  methods:
    courseLevels: (courseID) ->
      campaign = @courseCampaign(courseID)
      return [] unless campaign
      levels = Campaign.getLevels(campaign)
      return levels
      
    courseCampaign: (courseID) ->
      course = _.find(@courses, {_id: courseID})
      return unless course
      campaign = _.find(@campaigns, {_id: course.campaignID})
      return campaign

    levelNumberMapForCourse: (courseID) ->
      campaign = @courseCampaign(courseID)
      return {} unless campaign
      return Campaign.getLevelNumberMap(campaign)

  computed:
    levelConceptsBySlug: ->
      levelConcepts = {}
      seenConcepts = {}
      for course in @filteredCourses
        for level in @courseLevels(course._id)
          levelConcepts[level.slug] = []
          for concept in level.concepts or []
            unless seenConcepts[concept]
              levelConcepts[level.slug].push(concept)
            seenConcepts[concept] = true
      return levelConcepts

    filteredCourses: ->
      return _.filter(@courses, (course) =>
        if course.releasePhase isnt 'released'
          return false
        levels = @courseLevels(course.campaignID)
        unless levels
          return false
        return true
      )
      
    totalLevels: ->
      sum = _.reduce(@filteredCourses, (sum, course) =>
        return @courseLevels(course._id).length + sum
      , 0)


module.exports = class AdminClassroomLevelsView extends RootComponent
  id: 'admin-classroom-levels-view'
  template: template
  VueComponent: AdminClassroomLevelsComponent
