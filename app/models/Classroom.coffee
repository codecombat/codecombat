CocoModel = require './CocoModel'
schema = require 'schemas/models/classroom.schema'

module.exports = class Classroom extends CocoModel
  @className: 'Classroom'
  @schema: schema
  urlRoot: '/db/classroom'
