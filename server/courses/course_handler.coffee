mongoose = require 'mongoose'
Handler = require '../commons/Handler'
Course = require './Course'

CourseHandler = class CourseHandler extends Handler
  modelClass: Course
  jsonSchema: require '../../app/schemas/models/course.schema'
  allowedMethods: ['GET']

  hasAccess: (req) ->
    req.method in @allowedMethods or req.user?.isAdmin()

module.exports = new CourseHandler()
