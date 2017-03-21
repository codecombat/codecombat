mongoose = require 'mongoose'
plugins = require '../plugins/plugins'
config = require '../../server_config'

BranchSchema = new mongoose.Schema(body: String, {strict: false,read:config.mongo.readpref})

BranchSchema.plugin(plugins.NamedPlugin)

BranchSchema.statics.postEditableProperties = []
BranchSchema.statics.editableProperties = ['name', 'patches']
BranchSchema.statics.jsonSchema = require '../../app/schemas/models/branch.schema'

module.exports = mongoose.model('branch', BranchSchema)
