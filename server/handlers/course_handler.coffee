
mongoose = require 'mongoose'
Handler = require '../commons//Handler'
Course = require '../models/Course'

# TODO: Refactor PatchHandler.setStatus into its own route.
# This handler has been resurrected solely so that course patches can be accepted.

CourseHandler = class CourseHandler extends Handler
  modelClass: Course
  jsonSchema: require '../../app/schemas/models/course.schema'
  allowedMethods: []

  hasAccess: (req) ->
    req.method in @allowedMethods or req.user?.isAdmin()

  hasAccessToDocument: (req, document, method=null) ->
    method = (method or req.method).toLowerCase()
    return true if method is 'get'
    return true if req.user?.isAdmin() or req.user?.isArtisan()
    return

module.exports = new CourseHandler()
