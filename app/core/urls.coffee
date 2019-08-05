module.exports =
  projectGallery: ({ courseInstanceID }) ->
    return "/students/project-gallery/#{courseInstanceID}"

  playDevLevel: ({level, session, course}) ->
    level = level.attributes || level
    session = session.attributes || session
    course = course?.attributes || course
    shareURL = "#{window.location.origin}/play/#{level.type}-level/#{level.slug}/#{session._id}"
    shareURL += "?course=#{course._id}" if course
    return shareURL

  courseArenaLadder: ({level, courseInstance}) ->
    level = level.attributes || level
    courseInstance = courseInstance.attributes || courseInstance
    "/play/ladder/#{level.slug}/course/#{courseInstance._id}"

  courseLevel: ({level, courseInstance}) ->
    url = "/play/level/#{level.get('slug')}?course=#{courseInstance.get('courseID')}&course-instance=#{courseInstance.id}"
    url += "&codeLanguage=#{level.get('primerLanguage')}" if level.get('primerLanguage')
    url

  courseWorldMap: ({course, courseInstance}) ->
    course = course.attributes || course
    courseInstance = courseInstance.attributes || courseInstance
    "/play/#{course.campaignID}?course-instance=#{courseInstance._id}"

  courseRanking: ({course, courseInstance}) ->
    course = course.attributes || course
    courseInstance = courseInstance.attributes || courseInstance
    "students/ranking/#{course.campaignID}?course-instance=#{courseInstance._id}"

  courseProjectGallery: ({courseInstance}) ->
    "/students/project-gallery/#{courseInstance.id}"
