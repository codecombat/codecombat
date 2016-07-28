module.exports =
  playDevLevel: ({level, session, course}) ->
    shareURL = "#{window.location.origin}/play/#{level.get('type')}-level/#{level.get('slug')}/#{session.id}"
    shareURL += "?course=#{course.id}" if course
    return shareURL
