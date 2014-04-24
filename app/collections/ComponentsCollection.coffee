LevelComponent = require 'models/LevelComponent'
CocoCollection = require 'collections/CocoCollection'

module.exports = class ComponentsCollection extends CocoCollection
  url: '/db/level.component/search'
  model: LevelComponent
