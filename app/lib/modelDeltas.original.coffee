deltasLib = require('core/deltas')
jsondiffpatch = require('lib/jsondiffpatch')

module.exports = modelDeltas = {
  makePatch: (model) ->
    Patch = require 'models/Patch'
    target = {
      'collection': _.string.underscored model.constructor.className
      'id': model.id
    }
    # if this document is versioned (has original property) then include version info
    if model.get('original')
      target.original = model.get('original')
      target.version = model.get('version')

    return new Patch({
      delta: modelDeltas.getDelta(model)
      target
    })

  getDelta: (model) ->
    differ = deltasLib.makeJSONDiffer()
    differ.diff(_.omit(model._revertAttributes, deltasLib.DOC_SKIP_PATHS), _.omit(model.attributes, deltasLib.DOC_SKIP_PATHS))

  getDeltaWith: (model, otherModel) ->
    differ = deltasLib.makeJSONDiffer()
    differ.diff model.attributes, otherModel.attributes

  applyDelta: (model, delta) ->
    newAttributes = $.extend(true, {}, model.attributes)
    try
      jsondiffpatch.patch newAttributes, delta
    catch error
      unless application.testing
        console.error 'Error applying delta\n', JSON.stringify(delta, null, '\t'), '\n\nto attributes\n\n', newAttributes
      return false
    for key, value of newAttributes
      delete newAttributes[key] if _.isEqual value, model.attributes[key]

    model.set newAttributes
    return true

  getExpandedDelta: (model) ->
    delta = modelDeltas.getDelta(model)
    deltasLib.expandDelta(delta, model._revertAttributes, model.schema())

  getExpandedDeltaWith: (model, otherModel) ->
    delta = modelDeltas.getDeltaWith(model, otherModel)
    deltasLib.expandDelta(delta, model.attributes, model.schema())
}
