fetchJson = require './fetch-json'

module.exports = {
  get: ({courseID}, options={}) ->
    fetchJson("/db/course/#{courseID}", options)

  getAll: (options={}) ->
    fetchJson("/db/course", options)

  getReleased: (options={}) ->
    options.data ?= {}
    if me.isInternal()
      options.data.fetchInternal = true # will fetch 'released' and 'internalRelease' courses
    else
      options.data.releasePhase = 'released'
    fetchJson("/db/course", options)

  fetchChangeLog: (options = {}) ->
    fetchJson("/db/course/change-log", options)

  getAllClassroomLevels: (options = {}) ->
    fetchJson("/db/course/#{options.courseId}/get-all-classroom-levels")

  addLevelsForAllClassroomsDryRun: (options = {}) ->
    fetchJson("/db/course/#{options.courseId}/add-levels-for-all-classrooms")

  addLevelsForAllClasses: (options = {}) ->
    fetchJson("/db/course/#{options.courseId}/add-levels-for-all-classrooms/yes-really-update-all-classrooms!-this-is-not-a-drill!")
}
