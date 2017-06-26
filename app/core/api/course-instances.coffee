fetchJson = require './fetch-json'

module.exports = {
  get: ({ courseInstanceID }, options={}) ->
    fetchJson("/db/course_instance/#{courseInstanceID}", options)

  getProjectGallery: ({ courseInstanceID }, options={}) ->
    fetchJson("/db/course_instance/#{courseInstanceID}/peer-projects", options)
}
