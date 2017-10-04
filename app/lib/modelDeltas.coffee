deltasLib = require('core/deltas')

module.exports = modelDeltas = {
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
