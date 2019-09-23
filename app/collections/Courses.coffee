Course = require 'models/Course'
CocoCollection = require 'collections/CocoCollection'

module.exports = class Courses extends CocoCollection
  model: Course
  url: '/db/course'

  fetchReleased: (options = {}) ->
    options.data ?= {}
    options.data.releasePhase = 'released'
    options.data.isOzaria = true
    @fetch(options)
