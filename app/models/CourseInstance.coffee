CocoModel = require './CocoModel'
schema = require 'schemas/models/course_instance.schema'

module.exports = class CourseInstance extends CocoModel
  @className: 'CourseInstance'
  @schema: schema
  urlRoot: '/db/course_instance'

  createForHOC: ->
    # encapsulates creating a special course instance for HoC