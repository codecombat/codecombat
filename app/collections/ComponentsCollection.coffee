LevelComponent = require 'models/LevelComponent'
CocoCollection = require 'models/CocoCollection'

module.exports = class ComponentsCollection extends CocoCollection
  url: '/db/level.component/search'
  model: LevelComponent
