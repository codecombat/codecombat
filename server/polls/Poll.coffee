mongoose = require 'mongoose'
plugins = require '../plugins/plugins'
jsonSchema = require '../../app/schemas/models/poll.schema'
log = require 'winston'

PollSchema = new mongoose.Schema {
  created:
    type: Date
    'default': Date.now
}, {strict: false, minimize: false}

PollSchema.index {priority: 1}

# Just duplicating indexes that get created here by plugins for completeness
PollSchema.index {i18nCoverage: 1}, {name: 'translation coverage index', sparse: true}
PollSchema.index {slug: 1}, {name: 'slug index', sparse: true, unique: true}

PollSchema.plugin plugins.NamedPlugin
PollSchema.plugin plugins.PatchablePlugin
PollSchema.plugin plugins.TranslationCoveragePlugin
PollSchema.plugin plugins.SearchablePlugin, {searchable: ['name', 'description']}

PollSchema.statics.privateProperties = []
PollSchema.statics.editableProperties = [
  'name'
  'description'
  'answers'
  'i18n'
  'i18nCoverage'
  'priority'
  'userProperty'
]
PollSchema.statics.jsonSchema = jsonSchema

module.exports = Poll = mongoose.model 'poll', PollSchema, 'polls'
