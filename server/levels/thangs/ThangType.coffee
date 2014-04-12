mongoose = require('mongoose')
plugins = require('../../plugins/plugins')

ThangTypeSchema = new mongoose.Schema({
  body: String,
}, {strict: false})

ThangTypeSchema.plugin plugins.NamedPlugin
ThangTypeSchema.plugin plugins.VersionedPlugin
ThangTypeSchema.plugin plugins.SearchablePlugin, {searchable: ['name']}
ThangTypeSchema.plugin plugins.PatchablePlugin

module.exports = mongoose.model('thang.type', ThangTypeSchema)
