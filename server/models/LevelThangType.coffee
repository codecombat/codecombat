mongoose = require 'mongoose'
plugins = require '../plugins/plugins'

LevelComponentSchema = new mongoose.Schema(
  original: {type: mongoose.Schema.ObjectId, ref: 'level.session'}
  majorVersion: Number
)

ThangSoundSchema = new mongoose.Schema(
  events: [String]
  actions: [String]
  files: [String]
  delay: Number
)

SpriteHueLayer = new mongoose.Schema(
  name: String
  hueRange:
    min: Number
    max: Number
  saturationRange:
    min: Number
    max: Number
  brightnessRange:
    min: Number
    max: Number
)

LevelThangTypeSchema = new mongoose.Schema()

LevelThangTypeSchema.add(
  components: [LevelComponentSchema]
  description: String
  media:
    sounds: [ThangSoundSchema]
    display:
      alpha: Number
      children: [LevelThangTypeSchema]
      offset: [Number]
      hueLayers: [SpriteHueLayer]
      rotation: String
      scale:
        both: Number
        toWorld: Boolean
      shadow: String
      width: Number
      height: Number
      sheetFromFile:
        images: [String]
        frames: [Array]
        animations: mongoose.Schema.Types.Mixed
      customSheet:
        images: [String]
        frames: [Array]
        animations: mongoose.Schema.Types.Mixed
      z: Number
      image: String
)

LevelThangTypeSchema.plugin(plugins.PermissionsPlugin)
LevelThangTypeSchema.plugin(plugins.NamedPlugin)
LevelThangTypeSchema.plugin(plugins.SearchablePlugin, {searchable: ['name', 'description']})

module.exports = LevelThangType = mongoose.model('level.thang.type', LevelThangTypeSchema)
