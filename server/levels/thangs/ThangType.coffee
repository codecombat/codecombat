mongoose = require 'mongoose'
plugins = require '../../plugins/plugins'

ThangTypeSchema = new mongoose.Schema({
  body: String,
}, {strict:false, minimize: false})

ThangTypeSchema.plugin plugins.NamedPlugin
ThangTypeSchema.plugin plugins.VersionedPlugin
ThangTypeSchema.plugin plugins.SearchablePlugin, {searchable: ['name']}
ThangTypeSchema.plugin plugins.PatchablePlugin
ThangTypeSchema.plugin plugins.TranslationCoveragePlugin

module.exports = mongoose.model('thang.type', ThangTypeSchema)
