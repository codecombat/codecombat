mongoose = require 'mongoose'
config = require '../../server_config'
plugins = require '../plugins/plugins'
jsonSchema = require '../../app/schemas/models/course.schema'

CourseSchema = new mongoose.Schema {}, {strict: false, minimize: false, read:config.mongo.readpref}

CourseSchema.plugin plugins.NamedPlugin
CourseSchema.plugin plugins.SearchablePlugin, {searchable: ['name', 'description']}
CourseSchema.plugin(plugins.TranslationCoveragePlugin)

CourseSchema.statics.privateProperties = []
CourseSchema.statics.editableProperties = [
  'i18n',
  'i18nCoverage'
]

CourseSchema.statics.jsonSchema = jsonSchema

CourseSchema.statics.sortCourses = (courses) ->
  ordering = [
    'introduction-to-computer-science'
    'computer-science-2'
    'game-dev-1'
    'game-development-1'
    'web-dev-1'
    'web-development-1'
    'computer-science-3'
    'game-dev-2'
    'game-development-2'
    'web-dev-2'
    'web-development-2'
    'computer-science-4'
    'game-dev-3'
    'game-development-3'
    'web-dev-3'
    'web-development-3'
    'computer-science-5'
    'game-dev-4'
    'game-development-4'
    'web-dev-4'
    'web-development-4'
    'computer-science-6'
    'game-dev-5'
    'game-development-5'
    'web-dev-5'
    'web-development-5'
    'computer-science-7'
    'game-dev-6'
    'game-development-6'
    'web-dev-6'
    'web-development-6'
    'computer-science-8'
  ]
  _.sortBy courses, (course) ->
    index = ordering.indexOf(course.get?('slug') or course.slug)
    index = 9001 if index is -1
    index
    
CourseSchema.post 'init', (doc) ->
  if !doc.get('i18nCoverage')
    doc.set('i18nCoverage', [])

module.exports = Course = mongoose.model 'course', CourseSchema, 'courses'
