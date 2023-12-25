// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS104: Avoid inline assignments
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let AdminClassroomContentView
require('app/styles/admin/admin-classroom-content.sass')
const utils = require('core/utils')
const RootView = require('views/core/RootView')

module.exports = (AdminClassroomContentView = (function () {
  AdminClassroomContentView = class AdminClassroomContentView extends RootView {
    static initClass () {
      this.prototype.id = 'admin-classroom-content-view'
      this.prototype.template = require('app/templates/admin/admin-classroom-content')
    }

    initialize () {
      if (!me.isAdmin()) { return super.initialize() }
      this.minSessionCount = utils.getQueryVariable('minSessionCount', 50)
      this.maxDays = utils.getQueryVariable('maxDays', 20)
      this.maxPlaytimePerlevel = utils.getQueryVariable('maxPlaytimePerLevel', 60 * 60 * 1)
      this.minAge = utils.getQueryVariable('minAge')
      this.maxAge = utils.getQueryVariable('maxAge')
      if (this.minAge || this.maxAge) {
        this.loadingMessage = `Fetching students between ${this.minAge != null ? this.minAge : '?'} and ${this.maxAge != null ? this.maxAge : '?'}..`
        let url = '/db/users/-/by-age?'
        if (this.minAge) { url += `minAge=${this.minAge}&` }
        if (this.maxAge) { url += `maxAge=${this.maxAge}&` }
        Promise.resolve($.get(url))
          .then(results => {
            return this.fetchData(results)
          })
      } else {
        this.fetchData()
      }
      return super.initialize()
    }

    fetchData (userIds) {
      // Fetch playtime data for released courses
      // Makes a bunch of small fetches per course and per day to avoid gateway timeouts
      let courseID
      this.loadingMessage = 'Loading..'
      const courseLevelPlaytimesMap = {}
      const courseLevelTotalPlaytimeMap = {}
      const levelPracticeMap = {}
      const userIdMap = {}
      for (const id of Array.from((userIds || []))) { userIdMap[id] = true }
      var getMoreLevelSessions = (courseIDs, startOffset, endOffset) => {
        let endDay
        if (this.destroyed) { return }
        this.loadingMessage = `Fetching data for ${courseIDs.length} courses for ${endOffset != null ? endOffset : 0}/${this.maxDays} days ago..`
        if (typeof this.render === 'function') {
          this.render()
        }
        const startDate = new Date()
        startDate.setUTCDate(startDate.getUTCDate() - startOffset)
        const startDay = startDate.toISOString().substring(0, 10)
        if (endOffset) {
          const endDate = new Date()
          endDate.setUTCDate(endDate.getUTCDate() - endOffset)
          endDay = endDate.toISOString().substring(0, 10)
        }
        const promises = []
        for (courseID of Array.from(courseIDs)) {
          let url = `/db/classroom/-/playtimes?sessionLimit=${this.minSessionCount * 100}&courseID=${courseID}&startDay=${encodeURIComponent(startDay)}`
          if (endDay) { url += `&endDay=${encodeURIComponent(endDay)}` }
          promises.push(Promise.resolve($.get(url)))
        }
        return Promise.all(promises)
          .then(results => {
            let levelOriginal
            let courseID, levelPlaytimes, data
            if (this.destroyed) { return }

            for (let index = 0; index < results.length; index++) {
              var levelSessions
              data = results[index];
              [levelPlaytimes, levelSessions] = Array.from(data)
              if (!levelPlaytimes[0]) { continue }
              ({
                courseID
              } = levelPlaytimes[0])
              // console.log courseID, 'course sessions returned', levelSessions.length
              if (courseLevelPlaytimesMap[courseID] == null) { courseLevelPlaytimesMap[courseID] = levelPlaytimes }
              if (courseLevelTotalPlaytimeMap[courseID] == null) { courseLevelTotalPlaytimeMap[courseID] = {} }
              for (const levelPlaytime of Array.from(levelPlaytimes)) {
                if (courseLevelTotalPlaytimeMap[courseID][levelPlaytime.levelOriginal] == null) { courseLevelTotalPlaytimeMap[courseID][levelPlaytime.levelOriginal] = { count: 0, total: 0 } }
                if (levelPlaytime.practice) { levelPracticeMap[levelPlaytime.levelOriginal] = true }
              }
              for (const session of Array.from(levelSessions)) {
                if (session.playtime == null) { continue }
                if (userIds && !userIdMap[session.creator]) { continue }
                courseLevelTotalPlaytimeMap[courseID][session.level.original].count++
                courseLevelTotalPlaytimeMap[courseID][session.level.original].total += Math.min(session.playtime != null ? session.playtime : 0, this.maxPlaytimePerlevel)
              }
            }
            // console.log 'courseLevelTotalPlaytimeMap', courseLevelTotalPlaytimeMap

            for (courseID in courseLevelTotalPlaytimeMap) {
              const totalPlaytimes = courseLevelTotalPlaytimeMap[courseID]
              if (Array.from(courseIDs).includes(courseID)) {
                let needMoreData = false
                for (levelOriginal in totalPlaytimes) {
                  data = totalPlaytimes[levelOriginal]
                  if (data.count < this.minSessionCount) {
                    needMoreData = true
                    break
                  }
                }
                if (needMoreData) { continue }
                // console.log 'getMoreLevelSessions have enough data for course', courseID
                _.remove(courseIDs, val => val === courseID)
              }
            }

            if ((startOffset <= this.maxDays) && (courseIDs.length > 0)) {
              return getMoreLevelSessions(courseIDs, startOffset + 1, (endOffset + 1) || 1)
            } else {
              for (courseID in courseLevelPlaytimesMap) {
                levelPlaytimes = courseLevelPlaytimesMap[courseID]
                for (data of Array.from(levelPlaytimes)) {
                  data.count = (courseLevelTotalPlaytimeMap[courseID][data.levelOriginal] != null ? courseLevelTotalPlaytimeMap[courseID][data.levelOriginal].count : undefined) != null ? (courseLevelTotalPlaytimeMap[courseID][data.levelOriginal] != null ? courseLevelTotalPlaytimeMap[courseID][data.levelOriginal].count : undefined) : 0
                  data.playtime = (courseLevelTotalPlaytimeMap[courseID][data.levelOriginal] != null ? courseLevelTotalPlaytimeMap[courseID][data.levelOriginal].total : undefined) != null ? (courseLevelTotalPlaytimeMap[courseID][data.levelOriginal] != null ? courseLevelTotalPlaytimeMap[courseID][data.levelOriginal].total : undefined) : 0
                }
              }
              // console.log 'courseLevelPlaytimesMap', courseLevelPlaytimesMap

              this.courseLevelPlaytimes = _.flatten(((() => {
                const result = []
                for (courseID in courseLevelPlaytimesMap) {
                  levelPlaytimes = courseLevelPlaytimesMap[courseID]
                  result.push(levelPlaytimes)
                }
                return result
              })()))
              this.courseLevelPlaytimes.sort((a, b) => {
                let left, left1
                const aRank = (((left = utils.orderedCourseIDs.indexOf(a.courseID)) != null ? left : 9000) * 1000) + (a.levelIndex != null ? a.levelIndex : 500)
                const bRank = (((left1 = utils.orderedCourseIDs.indexOf(b.courseID)) != null ? left1 : 9000) * 1000) + (b.levelIndex != null ? b.levelIndex : 500)
                return aRank - bRank
              })

              this.totalSeconds = 0
              const courseSecondsMap = {}
              const courseIDMap = {}
              for (data of Array.from(this.courseLevelPlaytimes)) {
                if (courseSecondsMap[data.courseSlug] == null) { courseSecondsMap[data.courseSlug] = 0 }
                let avgPlaytime = data.count > 0 ? data.playtime / data.count : 300
                if (levelPracticeMap[data.levelOriginal]) { avgPlaytime /= 3 }
                courseIDMap[data.courseSlug] = data.courseID
                courseSecondsMap[data.courseSlug] += avgPlaytime
                this.totalSeconds += avgPlaytime
              }
              this.courseSeconds = ((() => {
                const result1 = []
                for (const courseSlug in courseSecondsMap) {
                  data = courseSecondsMap[courseSlug]
                  result1.push({ courseSlug, seconds: data })
                }
                return result1
              })())
              this.courseSeconds.sort((a, b) => utils.orderedCourseIDs.indexOf(courseIDMap[a.courseSlug]) - utils.orderedCourseIDs.indexOf(courseIDMap[b.courseSlug]))

              return (typeof this.render === 'function' ? this.render() : undefined)
            }
          })
      }

      return getMoreLevelSessions(((() => {
        const result = []
        for (const key in utils.courseIDs) {
          courseID = utils.courseIDs[key]
          result.push(courseID)
        }
        return result
      })()), 1)
    }
  }
  AdminClassroomContentView.initClass()
  return AdminClassroomContentView
})())
