module.exports =
  playDevLevel: ({level, session, course}) ->
    shareURL = "#{window.location.origin}/play/#{level.get('type')}-level/#{level.get('slug')}/#{session.id}"
    shareURL += "?course=#{course.id}" if course
    return shareURL

  courseArenaLadder: ({level, courseInstance}) ->
    "/play/ladder/#{level.get('slug')}/course/#{courseInstance.id}"

  courseLevel: ({level, courseInstance}) ->
    url = "/play/level/#{level.get('slug')}?course=#{courseInstance.get('courseID')}&course-instance=#{courseInstance.id}"
    url += "&codeLanguage=#{level.get('primerLanguage')}" if level.get('primerLanguage')
    url

  courseWorldMap: ({course, courseInstance, classroom}) ->
    "/play/#{course.get('campaignID')}?course-instance=#{courseInstance.id}"