mongoose = require 'mongoose'
plugins = require '../plugins/plugins'
config = require '../../server_config'

ThangTypeSchema = new mongoose.Schema({
  body: String,
}, {strict: false,read:config.mongo.readpref})

ThangTypeSchema.index(
  {
    index: 1
    _fts: 'text'
    _ftsx: 1
  },
  {
    name: 'search index'
    sparse: true
    weights: {name: 1}
    default_language: 'english'
    'language_override': 'searchLanguage'
    'textIndexVersion': 2
  })
ThangTypeSchema.index(
  {
    original: 1
    'version.major': -1
    'version.minor': -1
  },
  {
    name: 'version index'
    unique: true
  })
ThangTypeSchema.index({slug: 1}, {name: 'slug index', sparse: true, unique: true})

ThangTypeSchema.plugin plugins.NamedPlugin
ThangTypeSchema.plugin plugins.VersionedPlugin
ThangTypeSchema.plugin plugins.SearchablePlugin, {searchable: ['name']}
ThangTypeSchema.plugin plugins.PatchablePlugin
ThangTypeSchema.plugin plugins.TranslationCoveragePlugin

module.exports = mongoose.model('thang.type', ThangTypeSchema)
