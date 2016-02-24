PatchModel = require 'models/Patch'
CocoCollection = require 'collections/CocoCollection'

module.exports = class Patches extends CocoCollection
  model: PatchModel
