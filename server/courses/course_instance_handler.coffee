mongoose = require 'mongoose'
Handler = require '../commons/Handler'
CourseInstance = require './CourseInstance'

CourseInstanceHandler = class CourseInstanceHandler extends Handler
  modelClass: CourseInstance
  jsonSchema: require '../../app/schemas/models/course_instance.schema'
  allowedMethods: ['GET', 'POST', 'PUT', 'DELETE']

  hasAccess: (req) ->
    req.method is 'GET' or req.user?.isAdmin()

module.exports = new CourseInstanceHandler()
