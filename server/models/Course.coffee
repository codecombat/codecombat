mongoose = require 'mongoose'
config = require '../../server_config'
plugins = require '../plugins/plugins'
jsonSchema = require '../../app/schemas/models/course.schema'

CourseSchema = new mongoose.Schema {}, {strict: false, minimize: false, read:config.mongo.readpref}

CourseSchema.plugin plugins.NamedPlugin
CourseSchema.plugin plugins.SearchablePlugin, {searchable: ['name', 'description']}

CourseSchema.statics.privateProperties = []
CourseSchema.statics.editableProperties = []

CourseSchema.statics.jsonSchema = jsonSchema

module.exports = Course = mongoose.model 'course', CourseSchema, 'courses'
