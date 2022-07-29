module.exports =
  projectGallery: ({ courseInstanceID }) ->
    return "/students/project-gallery/#{courseInstanceID}"

  playDevLevel: ({level, session, course, courseInstanceId}) ->
    level = level.attributes || level
    session = session.attributes || session
    course = course?.attributes || course
    shareURL = "#{window.location.origin}/play/#{level.type}-level/#{level.slug}/#{session._id}"
    shareURL += "?course=#{course._id}" if course
    shareURL += "&course-instance=#{courseInstanceId}" if course && courseInstanceId
    return shareURL

  courseArenaLadder: ({level, courseInstance}) ->
    level = level.attributes || level
    courseInstance = courseInstance.attributes || courseInstance
    "/play/ladder/#{level.slug}/course/#{courseInstance._id}"

  courseLevel: ({level, courseInstance}) ->
    url = "/play/level/#{level.get('slug')}?course=#{courseInstance.get('courseID')}&course-instance=#{courseInstance.id}"
    url += "&codeLanguage=#{level.get('primerLanguage')}" if level.get('primerLanguage')
    url

  courseWorldMap: ({courseId, courseInstanceId, campaignPage, campaignId, codeLanguage}) ->
    unless campaignId
      console.error('courseWorldMap: campaign id is not defined')
      return ""
    url = "/play/#{encodeURIComponent(campaignId)}"
    queryParams = {}
    queryParams['course'] = encodeURIComponent(courseId) if courseId
    queryParams['course-instance'] = encodeURIComponent(courseInstanceId) if courseInstanceId
    queryParams['campaign-page'] = encodeURIComponent(campaignPage) if campaignPage
    queryParams['codeLanguage'] = encodeURIComponent(codeLanguage) if codeLanguage

    queryString = $.param(queryParams)
    if queryString
      url += "?#{queryString}"
    return url

  courseProjectGallery: ({courseInstance}) ->
    "/students/project-gallery/#{courseInstance.id}"
