mongoose = require 'mongoose'
log = require 'winston'
config = require '../../server_config'
plugins = require '../plugins/plugins'
User = require './User'
jsonSchema = require '../../app/schemas/models/clan.schema.coffee'

ClanSchema = new mongoose.Schema {}, {strict: false, minimize: false, read:config.mongo.readpref}

ClanSchema.pre 'save', (next) ->
  User.update {_id: @get('ownerID')}, {$addToSet: {clans: @get('_id')}}, (err) =>
    if err
      log.error err
      return next(err)
    next()

ClanSchema.statics.privateProperties = []
ClanSchema.statics.editableProperties = [
  'description'
  'members'
  'name'
  'type'
]

ClanSchema.plugin plugins.NamedPlugin

# TODO: Do we need this?
# ClanSchema.plugin plugins.SearchablePlugin, {searchable: ['name']}

ClanSchema.statics.jsonSchema = jsonSchema

module.exports = Clan = mongoose.model 'clan', ClanSchema, 'clans'
