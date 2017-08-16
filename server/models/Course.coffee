mongoose = require 'mongoose'
config = require '../../server_config'
plugins = require '../plugins/plugins'
jsonSchema = require '../../app/schemas/models/course.schema'
{sortCourses} = require '../../app/core/utils'

CourseSchema = new mongoose.Schema {}, {strict: false, minimize: false, read:config.mongo.readpref}

CourseSchema.index({releasePhase: 1}, {name: 'releasePhase index'})

CourseSchema.plugin plugins.NamedPlugin
CourseSchema.plugin plugins.SearchablePlugin, {searchable: ['name', 'description']}
CourseSchema.plugin(plugins.TranslationCoveragePlugin)
CourseSchema.plugin(plugins.PatchablePlugin)

CourseSchema.statics.privateProperties = []
CourseSchema.statics.editableProperties = [
  'i18n',
  'i18nCoverage'
]

CourseSchema.statics.jsonSchema = jsonSchema

CourseSchema.statics.sortCourses = (courses) ->
  sortCourses(courses)

CourseSchema.post 'init', (doc) ->
  if !doc.get('i18nCoverage')
    doc.set('i18nCoverage', [])

module.exports = Course = mongoose.model 'course', CourseSchema, 'courses'
