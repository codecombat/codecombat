// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
module.exports = {
  projectGallery ({ courseInstanceID }) {
    return `/students/project-gallery/${courseInstanceID}`
  },

  playDevLevel ({ level, session, course, courseInstanceId }) {
    level = level.attributes || level
    session = session.attributes || session
    course = (course != null ? course.attributes : undefined) || course
    let shareURL = `${window.location.origin}/play/${level.type}-level/${level.slug}/${session._id}`
    if (course) { shareURL += `?course=${course._id}` }
    if (course && courseInstanceId) { shareURL += `&course-instance=${courseInstanceId}` }
    return shareURL
  },

  courseArenaLadder ({ level, courseInstance }) {
    level = level.attributes || level
    courseInstance = courseInstance.attributes || courseInstance
    return `/play/ladder/${level.slug}/course/${courseInstance._id}`
  },

  courseLevel ({ level, courseInstance }) {
    let url = `/play/level/${level.get('slug')}?course=${courseInstance.get('courseID')}&course-instance=${courseInstance.id}`
    if (level.get('primerLanguage')) { url += `&codeLanguage=${level.get('primerLanguage')}` }
    return url
  },

  courseWorldMap (param) {
    const courseId = param.courseId || (param.course != null ? param.course.id : undefined) || (param.course != null ? param.course._id : undefined) || param.course
    const courseInstanceId = param.courseInstanceId || (param.courseInstance != null ? param.courseInstance.id : undefined) || (param.courseInstance != null ? param.courseInstance._id : undefined) || param.courseInstance
    const campaignId = param.campaignId || __guard__(param.course != null ? param.course.attributes : undefined, x => x.campaignID) || (param.course != null ? param.course.campaignID : undefined)
    const {
      campaignPage
    } = param
    const {
      codeLanguage
    } = param

    if (!campaignId) {
      console.error('courseWorldMap: campaign id is not defined')
      return ''
    }
    let url = `/play/${encodeURIComponent(campaignId)}`
    const queryParams = {}
    if (courseId) { queryParams.course = encodeURIComponent(courseId) }
    if (courseInstanceId) { queryParams['course-instance'] = encodeURIComponent(courseInstanceId) }
    if (campaignPage) { queryParams['campaign-page'] = encodeURIComponent(campaignPage) }
    if (codeLanguage) { queryParams.codeLanguage = encodeURIComponent(codeLanguage) }
    const queryString = $.param(queryParams)
    if (queryString) {
      url += `?${queryString}`
    }
    return url
  },

  courseProjectGallery ({ courseInstance }) {
    return `/students/project-gallery/${courseInstance.id}`
  }
}

function __guard__ (value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined
}
