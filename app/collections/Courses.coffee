Course = require 'models/Course'
CocoCollection = require 'collections/CocoCollection'

module.exports = class Courses extends CocoCollection
  model: Course
  url: '/db/course'

  fetchReleased: (options = {}) ->
    options.data ?= {}
    # TODO: Add this restriction back as we launch Ozaria 1FH and start work on 1UP
    # in order to not show unreleased courses before they are ready. 
    # options.data.releasePhase = 'released'
    options.data.isOzaria = true
    @fetch(options)
  
  fetch: (options = {}) ->
    options.data ?= {}
    options.data.isOzaria = true 
    super(options)
