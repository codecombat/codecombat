const helper = require('lib/coursesHelper')
const utils = require('core/utils')

function __guard__ (value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined
}

if (window.saveAs == null) { window.saveAs = require('file-saver/FileSaver.js') } // `window.` is necessary for spec to spy on it
if (window.saveAs.saveAs) { window.saveAs = window.saveAs.saveAs } // Module format changed with webpack?

module.exports = {
  exportStudentProgress ({ classroom, sortedCourses, students, courses, courseInstances, levels, progressData }) {
    // TODO: Does not yield .csv download on Safari, and instead opens a new tab with the .csv contents
    let course, index, trimCourse, trimLevel
    let c
    if (window.tracker != null) {
      window.tracker.trackEvent('Teachers Class Export CSV', { category: 'Teachers', classroomID: classroom.id })
    }
    let courseLabels = ''
    const courseIds = ((() => {
      const result = []
      for (c of Array.from(sortedCourses)) {
        result.push(courses.get(c._id))
      }
      return result
    })())
    const courseLabelsArray = helper.courseLabelsArray(courseIds)
    for (index = 0; index < courseIds.length; index++) {
      course = courseIds[index]
      courseLabels += `${courseLabelsArray[index]} Levels,${courseLabelsArray[index]} Playtime(humanize),${courseLabelsArray[index]} Playtime(seconds),`
    }
    let csvContent = `Name,Username,Email,Total Levels,Total Playtime(humanize), Total Playtime(seconds),${courseLabels}Concepts\n`
    const levelCourseIdMap = {}
    const levelPracticeMap = {}
    const language = __guard__(classroom.get('aceConfig'), x => x.language)
    for (trimCourse of Array.from(classroom.getSortedCourses())) {
      for (trimLevel of Array.from(trimCourse.levels)) {
        if (language && (trimLevel.primerLanguage === language)) { continue }
        if (trimLevel.practice) {
          levelPracticeMap[trimLevel.original] = true
          continue
        }
        levelCourseIdMap[trimLevel.original] = trimCourse._id
      }
    }
    for (const student of Array.from(students.models)) {
      let courseID, level
      let concepts = []
      for (trimCourse of Array.from(classroom.getSortedCourses())) {
        course = courses.get(trimCourse._id)
        const instance = courseInstances.findWhere({ courseID: course.id, classroomID: classroom.id })
        if (instance && instance.hasMember(student)) {
          for (trimLevel of Array.from(trimCourse.levels)) {
            level = levels.findWhere({ original: trimLevel.original })
            if (level.get('assessment')) { continue }
            const progress = progressData.get({ classroom, course, level, user: student })
            if (progress != null ? progress.completed : undefined) {
              let left
              concepts.push((left = level.get('concepts')) != null ? left : [])
            }
          }
        }
      }
      concepts = _.union(_.flatten(concepts))
      const conceptsString = _.map(concepts, c => $.i18n.t('concepts.' + c)).join(', ')
      const courseCountsMap = {}
      let levelsCount = 0
      let playtime = 0
      for (const session of Array.from(classroom.sessions.models)) {
        if (session.get('creator') !== student.id) { continue }
        if (!__guard__(session.get('state'), x1 => x1.complete)) { continue }
        if (levelPracticeMap[__guard__(session.get('level'), x2 => x2.original)]) { continue }
        level = levels.findWhere({ original: __guard__(session.get('level'), x3 => x3.original) })
        if (level != null ? level.get('assessment') : undefined) { continue }
        levelsCount++
        playtime += session.get('playtime') || 0
        courseID = levelCourseIdMap[__guard__(session.get('level'), x4 => x4.original)]
        if (courseID) {
          if (courseCountsMap[courseID] == null) { courseCountsMap[courseID] = { levels: 0, playtime: 0 } }
          courseCountsMap[courseID].levels++
          courseCountsMap[courseID].playtime += session.get('playtime') || 0
        }
      }
      const playtimeString = playtime === 0 ? '0' : moment.duration(playtime, 'seconds').humanize()
      for (course of Array.from(sortedCourses)) {
        if (courseCountsMap[course._id] == null) { courseCountsMap[course._id] = { levels: 0, playtime: 0 } }
      }
      const courseCounts = []
      for (course of Array.from(sortedCourses)) {
        courseID = course._id
        const data = courseCountsMap[courseID]
        courseCounts.push({
          id: courseID,
          levels: data.levels,
          playtime: data.playtime
        })
      }
      utils.sortCourses(courseCounts)
      let courseCountsString = ''
      for (index = 0; index < courseCounts.length; index++) {
        const counts = courseCounts[index]
        courseCountsString += `${counts.levels},`
        if (counts.playtime === 0) {
          courseCountsString += '0,0,'
        } else {
          courseCountsString += `${moment.duration(counts.playtime, 'seconds').humanize()},${counts.playtime},`
        }
      }
      csvContent += `${student.broadName()},${student.get('name')},${student.get('email') || ''},${levelsCount},${playtimeString},${playtime},${courseCountsString}"${conceptsString}"\n`
    }
    csvContent = csvContent.substring(0, csvContent.length - 1)
    const file = new Blob([csvContent], { type: 'text/csv;charset=utf-8' })
    return window.saveAs(file, 'CodeCombat.csv')
  }
}
