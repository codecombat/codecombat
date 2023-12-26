/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
module.exports = {
  projectGallery ({ courseInstanceID }) {
    return `/students/project-gallery/${courseInstanceID}`
  },

  playDevLevel ({ level, session, course, courseInstanceId }) {
    level = level.attributes || level
    session = session.attributes || session
    course = course?.attributes || course
    let shareURL = `${window.location.origin}/play/${level.type}-level/${level.slug}/${session._id}`
    if (course) {
      shareURL += `?course=${course._id}`
    }
    if (course && courseInstanceId) {
      shareURL += `&course-instance=${courseInstanceId}`
    }
    return shareURL
  },

  courseArenaLadder ({ level, courseInstance }) {
    level = level.attributes || level
    courseInstance = courseInstance.attributes || courseInstance
    return `/play/ladder/${level.slug}/course/${courseInstance._id}`
  },

  courseLevel ({ level, courseInstance }) {
    let url = `/play/level/${level.get('slug')}?course=${courseInstance.get(
      'courseID'
    )}&course-instance=${courseInstance.id}`
    if (level.get('primerLanguage')) {
      url += `&codeLanguage=${level.get('primerLanguage')}`
    }
    return url
  },

  courseWorldMap (param) {
    const courseId =
      param.courseId || param.course?.id || param.course?._id || param.course
    const courseInstanceId =
      param.courseInstanceId ||
      param.courseInstance?.id ||
      param.courseInstance?._id ||
      param.courseInstance
    const campaignId =
      param.campaignId ||
      param.course?.attributes?.campaignID ||
      param.course?.campaignID
    const classroomId = param.classroom?.id || param.classroomId
    const { campaignPage } = param
    const { codeLanguage } = param
    if (!campaignId) {
      console.error('courseWorldMap: campaign id is not defined')
      return ''
    }
    let url = `/play/${encodeURIComponent(campaignId)}`
    const queryParams = {}
    if (courseId) {
      queryParams.course = encodeURIComponent(courseId)
    }
    if (courseInstanceId) {
      queryParams['course-instance'] = encodeURIComponent(courseInstanceId)
    }
    if (campaignPage) {
      queryParams['campaign-page'] = encodeURIComponent(campaignPage)
    }
    if (codeLanguage) {
      queryParams.codeLanguage = encodeURIComponent(codeLanguage)
    }
    if (classroomId) {
      queryParams['classroom-id'] = encodeURIComponent(classroomId)
    }
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
