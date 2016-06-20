CocoModel = require './CocoModel'
schema = require 'schemas/models/course.schema'

module.exports = class Course extends CocoModel
  @className: 'Course'
  @schema: schema
  urlRoot: '/db/course'
