LevelComponent = require 'models/LevelComponent'
CocoCollection = require 'collections/CocoCollection'

module.exports = class LevelComponents extends CocoCollection
  url: '/db/level.component'
  model: LevelComponent
