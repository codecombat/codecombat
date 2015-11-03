mongoose = require 'mongoose'
config = require '../../server_config'
plugins = require '../plugins/plugins'
jsonSchema = require '../../app/schemas/models/course_instance.schema'

CourseInstanceSchema = new mongoose.Schema {}, {strict: false, minimize: false, read:config.mongo.readpref}

CourseInstanceSchema.statics.privateProperties = []
CourseInstanceSchema.statics.editableProperties = [
  'description'
  'members'
  'name'
  'aceConfig'
]

CourseInstanceSchema.statics.jsonSchema = jsonSchema

module.exports = CourseInstance = mongoose.model 'course.instance', CourseInstanceSchema, 'course.instances'
