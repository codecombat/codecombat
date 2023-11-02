CocoCollection = require 'collections/CocoCollection'
Concept = require 'models/Concept'

module.exports = class ConceptCollection extends CocoCollection
  url: '/db/concept'
  model: Concept