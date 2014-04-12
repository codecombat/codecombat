# TODO: not updated since rename from level_instance, or since we redid how all models are done; probably busted

mongoose = require('mongoose')
plugins = require('../../plugins/plugins')
jsonschema = require('../../../app/schemas/models/level_session')

LevelSessionSchema = new mongoose.Schema({
  created:
    type: Date
    'default': Date.now
}, {strict: false})
LevelSessionSchema.plugin(plugins.PermissionsPlugin)

LevelSessionSchema.pre 'init', (next) ->
  # TODO: refactor this into a set of common plugins for all models?
  return next() unless jsonschema.properties?
  for prop, sch of jsonschema.properties
    @set(prop, _.cloneDeep(sch.default)) if sch.default?
  next()

LevelSessionSchema.pre 'save', (next) ->
  @set('changed', new Date())
  next()

module.exports = LevelSession = mongoose.model('level.session', LevelSessionSchema)