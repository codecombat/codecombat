utils = require 'core/utils'
RootView = require 'views/core/RootView'

module.exports = class AdminClassroomContentView extends RootView
  id: 'admin-classroom-content-view'
  template: require 'templates/admin/admin-classroom-content'

  initialize: ->
    return super() unless me.isAdmin()
    @fetchData()
    super()

  fetchData: ->
    # Fetch playtime data for released courses
    # Makes a bunch of small fetches per course and per day to avoid gateway timeouts
    @minSessionCount = 50
    @maxDays = 15
    @loadingMessage = "Loading.."
    courseLevelPlaytimesMap = {}
    courseLevelTotalPlaytimeMap = {}
    getMoreLevelSessions = (courseIDs, startOffset, endOffset) =>
      return if @destroyed
      @loadingMessage = "Fetching data for #{courseIDs.length} courses for #{endOffset ? 0}/#{@maxDays} days ago.."
      @render?()
      startDate = new Date()
      startDate.setUTCDate(startDate.getUTCDate() - startOffset)
      startDay = startDate.toISOString().substring(0, 10)
      if endOffset
        endDate = new Date()
        endDate.setUTCDate(endDate.getUTCDate() - endOffset)
        endDay = endDate.toISOString().substring(0, 10)
      promises = []
      for courseID in courseIDs
        url = "/db/classroom/-/playtimes?sessionLimit=#{@minSessionCount * 100}&courseID=#{courseID}&startDay=#{encodeURIComponent(startDay)}"
        if endDay
          url += "&endDay=#{encodeURIComponent(endDay)}"
        promises.push(Promise.resolve($.get(url)))
      Promise.all(promises)
      .then (results) =>
        return if @destroyed

        for data, index in results
          [levelPlaytimes, levelSessions] = data
          continue unless levelPlaytimes[0]
          courseID = levelPlaytimes[0].courseID
          courseLevelPlaytimesMap[courseID] ?= levelPlaytimes
          courseLevelTotalPlaytimeMap[courseID] ?= {}
          for levelPlaytime in levelPlaytimes
            courseLevelTotalPlaytimeMap[courseID][levelPlaytime.levelOriginal] ?= {count: 0, total: 0}
          for session in levelSessions
            courseLevelTotalPlaytimeMap[courseID][session.level.original].count++
            courseLevelTotalPlaytimeMap[courseID][session.level.original].total += session.playtime
        # console.log 'courseLevelTotalPlaytimeMap', courseLevelTotalPlaytimeMap

        for courseID, totalPlaytimes of courseLevelTotalPlaytimeMap when courseID in courseIDs
          needMoreData = false
          for levelOriginal, data of totalPlaytimes
            if data.count < @minSessionCount
              needMoreData = true
              break
          continue if needMoreData
          # console.log 'getMoreLevelSessions have enough data for course', courseID
          _.remove courseIDs, (val) -> val is courseID

        if startOffset <= @maxDays and courseIDs.length > 0
          return getMoreLevelSessions(courseIDs, startOffset + 1, endOffset + 1 or 1)
        else
          for courseID, levelPlaytimes of courseLevelPlaytimesMap
            for data in levelPlaytimes
              data.count = courseLevelTotalPlaytimeMap[courseID][data.levelOriginal]?.count ? 0
              data.playtime = courseLevelTotalPlaytimeMap[courseID][data.levelOriginal]?.total ? 0
          # console.log 'courseLevelPlaytimesMap', courseLevelPlaytimesMap

          @courseLevelPlaytimes = _.flatten((levelPlaytimes for courseID, levelPlaytimes of courseLevelPlaytimesMap))
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
    getMoreLevelSessions((courseID for key, courseID of utils.courseIDs), 1)
