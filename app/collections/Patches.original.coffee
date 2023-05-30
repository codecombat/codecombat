PatchModel = require 'models/Patch'
CocoCollection = require 'collections/CocoCollection'

module.exports = class Patches extends CocoCollection
  model: PatchModel

  fetchMineFor: (targetModel, options={}) ->
    options.url = "#{_.result(targetModel, 'url')}/patches"
    options.data ?= {}
    options.data.creator = me.id
    @fetch(options)
