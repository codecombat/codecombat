LevelSystem = require 'models/LevelSystem'
CocoCollection = require 'collections/CocoCollection'

module.exports = class LevelSystems extends CocoCollection
  url: '/db/level.system'
  model: LevelSystem
