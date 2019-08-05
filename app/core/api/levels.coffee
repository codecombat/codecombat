fetchJson = require './fetch-json'

module.exports = {
  getByOriginal: (original, options={}) ->
    return fetchJson("/db/level/#{original}/version", _.merge({}, options))

  getByIdOrSlug: (idOrSlug, options={}) ->
    return fetchJson("/db/level/#{idOrSlug}", _.merge({}, options))

  fetchNextForCourse: ({ levelOriginalID, courseInstanceID, courseID, sessionID }, options={}) ->
    if courseInstanceID
      url = "/db/course_instance/#{courseInstanceID}/levels/#{levelOriginalID}/sessions/#{sessionID}/next"
    else
      url = "/db/course/#{courseID}/levels/#{levelOriginalID}/next"
    return fetchJson(url, options)

  save: (level, options={}) ->
    fetchJson("/db/level/#{level._id}", _.assign({}, options, {
      method: 'POST'
      json: level
    }))

  upsertSession: (levelId, options={}) ->
    if options.courseInstanceId
      url = "/db/level/#{levelId}/session?courseInstanceId=#{encodeURIComponent(options.courseInstanceId)}"
    else
      url = "/db/level/#{levelId}/session"
    return fetchJson(url, options)
}
