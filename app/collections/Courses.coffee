Course = require 'models/Course'
CocoCollection = require 'collections/CocoCollection'

module.exports = class Courses extends CocoCollection
  model: Course
  url: '/db/course'

  fetchReleased: (options = {}) ->
    options.data ?= {}
    if me.isInternal()
      options.data.fetchInternal = true # will fetch 'released' and 'internalRelease' courses
    else
      options.data.releasePhase = 'released'
    @fetch(options)
