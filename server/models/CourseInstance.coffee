mongoose = require 'mongoose'
config = require '../../server_config'
plugins = require '../plugins/plugins'
jsonSchema = require '../../app/schemas/models/course_instance.schema.coffee'

CourseInstanceSchema = new mongoose.Schema {
  ownerID: mongoose.Schema.Types.ObjectId
  courseID: mongoose.Schema.Types.ObjectId
  classroomID: mongoose.Schema.Types.ObjectId
  prepaidID: mongoose.Schema.Types.ObjectId
  members: [mongoose.Schema.Types.ObjectId]
}, {strict: false, minimize: false, read:config.mongo.readpref}

CourseInstanceSchema.index({ownerID: 1}, {name: 'ownerID index'})
CourseInstanceSchema.index({members: 1}, {name: 'members index'})
CourseInstanceSchema.index({classroomID: 1}, {name: 'classroomID index', sparse: true})
CourseInstanceSchema.index({prepaidID: 1}, {name: 'prepaidID index', sparse: true})  # Deprecated? Can we get rid of this?

CourseInstanceSchema.statics.privateProperties = []
CourseInstanceSchema.statics.editableProperties = [
  'description'
  'name'
  'aceConfig'
]
CourseInstanceSchema.statics.postEditableProperties = [
  'courseID'
  'classroomID'
]

CourseInstanceSchema.statics.jsonSchema = jsonSchema

module.exports = CourseInstance = mongoose.model 'course.instance', CourseInstanceSchema, 'course.instances'
