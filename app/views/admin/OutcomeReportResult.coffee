utils = require 'core/utils'
RootView = require 'views/core/RootView'

module.exports = class OutcomesReportResult extends RootView
  id: 'admin-outcomes-report-result-view'
  template: require 'templates/admin/outcome-report-results'

  initialize: (@options) ->
    return super() unless me.isAdmin()
    @fetchData()
    super()

  fetchData: ->
    # Fetch playtime data for released courses
    # Makes a bunch of small fetches per course and per day to avoid gateway timeouts
    @minSessionCount = 50
    @maxDays = 20
    @loadingMessage = "Loading..."
    courseLevelPlaytimesMap = {}
    courseLevelTotalPlaytimeMap = {}
    levelPracticeMap = {}
    @courses = [
      {
        name: "Introduction to Computer Science"
        completion: (Math.random()*100).toFixed(0)
      }
      {
        name: "Computer Science 2"
        completion: (Math.random()*100).toFixed(0)
      }
      {
        name: "Web Development 1"
        completion: (Math.random()*100).toFixed(0)
      }
      {
        name: "Robin Class 6"
        completion: (Math.random()*100).toFixed(0)
      }

    ]

    @classes = [
      {
        name: "6th Grade Computers"
      }
      {
        name: "Robotics Club"
      }
    ]
    
