utils = require 'core/utils'
RootView = require 'views/core/RootView'

module.exports = class AdminClassroomContentView extends RootView
  id: 'admin-classroom-content-view'
  template: require 'templates/admin/admin-classroom-content'

  initialize: ->
    return super() unless me.isAdmin()
    @minSessionCount = 40
    $.get "/db/classroom/-/playtimes?minSessionCount=#{@minSessionCount}", (data) =>
      return if @destroyed
      @courseLevelPlaytimes = data
      @totalSeconds = 0
      courseSecondsMap = {}
      courseIDMap = {}
      for data in @courseLevelPlaytimes
        courseSecondsMap[data.courseSlug] ?= 0
        courseIDMap[data.courseSlug] = data.courseID
        if data.count > 0
          courseSecondsMap[data.courseSlug] += (data.playtime / data.count)
          @totalSeconds += (data.playtime / data.count)
        else
          courseSecondsMap[data.courseSlug] += 300
          @totalSeconds += 300
      @courseLevelPlaytimes.sort (a, b) =>
        aRank = (utils.orderedCourseIDs.indexOf(a.courseID) ? 9000) * 1000 + (a.levelIndex ? 500)
        bRank = (utils.orderedCourseIDs.indexOf(b.courseID) ? 9000) * 1000 + (b.levelIndex ? 500)
        aRank - bRank
      @courseSeconds = (courseSlug: courseSlug, seconds: data for courseSlug, data of courseSecondsMap)
      @courseSeconds.sort (a, b) ->
        utils.orderedCourseIDs.indexOf(courseIDMap[a.courseSlug]) - utils.orderedCourseIDs.indexOf(courseIDMap[b.courseSlug])
      @render?()
    .fail (jqXHR, textStatus, errorThrown) =>
      console.error textStatus, errorThrown
    super()
