CocoModel = require './CocoModel'
schema = require 'schemas/models/course.schema'
utils = require 'core/utils'

module.exports = class Course extends CocoModel
  @className: 'Course'
  @schema: schema
  urlRoot: '/db/course'

  fetchForCourseInstance: (courseInstanceID, opts) ->
    options = {
      url: "/db/course_instance/#{courseInstanceID}/course"
    }
    _.extend options, opts
    @fetch options

  acronym: ->
    utils.courseAcronyms[@get('_id')]

  isCh1Course: () ->
    @get('_id') == utils.courseIDs.CHAPTER_ONE
