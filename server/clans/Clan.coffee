mongoose = require 'mongoose'
log = require 'winston'
config = require '../../server_config'
plugins = require '../plugins/plugins'
jsonSchema = require '../../app/schemas/models/clan.schema'

ClanSchema = new mongoose.Schema {}, {strict: false, minimize: false, read:config.mongo.readpref}

ClanSchema.statics.privateProperties = []
ClanSchema.statics.editableProperties = [
  'type'
  'name'
  'members'
]

ClanSchema.plugin plugins.NamedPlugin
ClanSchema.plugin plugins.SearchablePlugin, {searchable: ['name']}

ClanSchema.statics.jsonSchema = jsonSchema

module.exports = Clan = mongoose.model 'clan', ClanSchema, 'clans'
