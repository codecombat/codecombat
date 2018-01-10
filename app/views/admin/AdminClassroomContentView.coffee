require('app/styles/admin/admin-classroom-content.sass')
utils = require 'core/utils'
RootView = require 'views/core/RootView'

module.exports = class AdminClassroomContentView extends RootView
  id: 'admin-classroom-content-view'
  template: require 'templates/admin/admin-classroom-content'

  initialize: ->
    return super() unless me.isAdmin()
    @minSessionCount = utils.getQueryVariable('minSessionCount', 50)
    @maxDays = utils.getQueryVariable('maxDays', 20)
    @maxPlaytimePerlevel = utils.getQueryVariable('maxPlaytimePerLevel', 60 * 60 * 1)
    @minAge = utils.getQueryVariable('minAge')
    @maxAge = utils.getQueryVariable('maxAge')
    if @minAge or @maxAge
      @loadingMessage = "Fetching students between #{@minAge ? '?'} and #{@maxAge ? '?'}.."
      url = "/db/users/-/by-age?"
      url += "minAge=#{@minAge}&" if @minAge
      url += "maxAge=#{@maxAge}&" if @maxAge
      Promise.resolve($.get(url))
      .then (results) =>
        @fetchData(results)
    else
      @fetchData()
    super()

  fetchData: (userIds) ->
    # Fetch playtime data for released courses
    # Makes a bunch of small fetches per course and per day to avoid gateway timeouts
    @loadingMessage = "Loading.."
    courseLevelPlaytimesMap = {}
    courseLevelTotalPlaytimeMap = {}
    levelPracticeMap = {}
    userIdMap = {}
    userIdMap[id] = true for id in (userIds or [])
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
        url += "&endDay=#{encodeURIComponent(endDay)}" if endDay
        promises.push(Promise.resolve($.get(url)))
      Promise.all(promises)
      .then (results) =>
        return if @destroyed

        for data, index in results
          [levelPlaytimes, levelSessions] = data
          continue unless levelPlaytimes[0]
          courseID = levelPlaytimes[0].courseID
          # console.log courseID, 'course sessions returned', levelSessions.length
          courseLevelPlaytimesMap[courseID] ?= levelPlaytimes
          courseLevelTotalPlaytimeMap[courseID] ?= {}
          for levelPlaytime in levelPlaytimes
            courseLevelTotalPlaytimeMap[courseID][levelPlaytime.levelOriginal] ?= {count: 0, total: 0}
            levelPracticeMap[levelPlaytime.levelOriginal] = true if levelPlaytime.practice
          for session in levelSessions
            continue unless session.playtime?
            continue if userIds and not userIdMap[session.creator]
            courseLevelTotalPlaytimeMap[courseID][session.level.original].count++
            courseLevelTotalPlaytimeMap[courseID][session.level.original].total += Math.min(session.playtime ? 0, @maxPlaytimePerlevel)
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
          @courseLevelPlaytimes.sort (a, b) =>
            aRank = (utils.orderedCourseIDs.indexOf(a.courseID) ? 9000) * 1000 + (a.levelIndex ? 500)
            bRank = (utils.orderedCourseIDs.indexOf(b.courseID) ? 9000) * 1000 + (b.levelIndex ? 500)
            aRank - bRank

          @totalSeconds = 0
          courseSecondsMap = {}
          courseIDMap = {}
          for data in @courseLevelPlaytimes
            courseSecondsMap[data.courseSlug] ?= 0
            avgPlaytime = if data.count > 0 then data.playtime / data.count else 300
            avgPlaytime /= 3 if levelPracticeMap[data.levelOriginal]
            courseIDMap[data.courseSlug] = data.courseID
            courseSecondsMap[data.courseSlug] += avgPlaytime
            @totalSeconds += avgPlaytime
          @courseSeconds = (courseSlug: courseSlug, seconds: data for courseSlug, data of courseSecondsMap)
          @courseSeconds.sort (a, b) ->
            utils.orderedCourseIDs.indexOf(courseIDMap[a.courseSlug]) - utils.orderedCourseIDs.indexOf(courseIDMap[b.courseSlug])

          @render?()

    getMoreLevelSessions((courseID for key, courseID of utils.courseIDs), 1)
