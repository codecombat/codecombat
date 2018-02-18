mongoose = require 'mongoose'
plugins = require '../plugins/plugins'
jsonSchema = require '../../app/schemas/models/level'
config = require '../../server_config'

LevelSchema = new mongoose.Schema({
  description: String
}, {strict: false, read:config.mongo.readpref})

LevelSchema.index(
  {
    index: 1
    _fts: 'text'
    _ftsx: 1
  },
  {
    name: 'search index'
    sparse: true
    weights: {description: 1, name: 1}
    default_language: 'english'
    'language_override': 'searchLanguage'
    'textIndexVersion': 2
  })

LevelSchema.index(
  {
    original: 1
    'version.major': -1
    'version.minor': -1
  },
  {
    name: 'version index'
    unique: true
  })
LevelSchema.index({slug: 1}, {name: 'slug index', sparse: true, unique: true})
LevelSchema.index({index: 1}, {name: 'index index', sparse: true})  # because we can't use the text search index with no term

LevelSchema.plugin(plugins.NamedPlugin)
LevelSchema.plugin(plugins.PermissionsPlugin)
LevelSchema.plugin(plugins.VersionedPlugin)
LevelSchema.plugin(plugins.SearchablePlugin, {searchable: ['name', 'description']})
LevelSchema.plugin(plugins.PatchablePlugin)
LevelSchema.plugin(plugins.TranslationCoveragePlugin)

LevelSchema.post 'init', (doc) ->
  if _.isString(doc.get('nextLevel'))
    doc.set('nextLevel', undefined)

LevelSchema.post 'save', (doc) ->
  return unless doc.get('version').isLatestMajor
  Campaign = require('./Campaign')
  # Leave setting campaign and campaignIndex to CampaignEditorView. In particular, for non-course levels
  # we want campaignIndex on the campaign level object, but not on the level document.
  denormalizedLevelProperties = _.without(Campaign.jsonSchema.denormalizedLevelProperties, 'campaignIndex', 'campaign')
  update = { $set: {}, $unset: {} }
  for property in denormalizedLevelProperties
    path = "levels.#{doc.get('original')}.#{property}"
    value = doc.get(property)
    if value?
      update.$set[path] = value
    else
      update.$unset[path] = ''
  delete update.$unset if _.isEmpty(update.$unset)
  delete update.$set if _.isEmpty(update.$set)
  return if _.isEmpty(update)
  query = {}
  query["levels.#{doc.get('original')}"] = {$exists: true}
  Campaign.update(query, update, {multi:true}).exec()

LevelSchema.statics.postEditableProperties = ['name']
LevelSchema.statics.jsonSchema = jsonSchema

LevelSchema.statics.editableProperties = [
  'description'
  'documentation'
  'nextLevel'
  'scripts'
  'thangs'
  'systems'
  'victory'
  'name'
  'i18n'
  'goals'
  'type'
  'kind'
  'banner'
  'terrain'
  'i18nCoverage'
  'loadingTip'
  'requiresSubscription'
  'adventurer'
  'practice'
  'assessment'
  'assessmentPlacement'
  'shareable'
  'adminOnly'
  'disableSpaces'
  'hidesSubmitUntilRun'
  'hidesPlayButton'
  'hidesRunShortcut'
  'hidesHUD'
  'hidesSay'
  'hidesCodeToolbar'
  'hidesRealTimePlayback'
  'backspaceThrottle'
  'lockDefaultCode'
  'moveRightLoopSnippet'
  'realTimeSpeedFactor'
  'autocompleteFontSizePx'
  'requiredCode'
  'suspectCode'
  'requiredGear'
  'restrictedGear'
  'requiredProperties'
  'restrictedProperties'
  'recommendedHealth'
  'allowedHeroes'
  'tasks'
  'helpVideos'
  'campaign'
  'campaignIndex'
  'replayable'
  'buildTime'
  'scoreTypes'
  'concepts'
  'primaryConcepts'
  'picoCTFProblem'
  'practiceThresholdMinutes'
  'primerLanguage'
  'studentPlayInstructions'
]


module.exports = Level = mongoose.model('level', LevelSchema)
