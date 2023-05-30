/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let modelDeltas;
const deltasLib = require('core/deltas');
const jsondiffpatch = require('lib/jsondiffpatch');

module.exports = (modelDeltas = {
  makePatch(model) {
    const Patch = require('models/Patch');
    const target = {
      'collection': _.string.underscored(model.constructor.className),
      'id': model.id
    };
    // if this document is versioned (has original property) then include version info
    if (model.get('original')) {
      target.original = model.get('original');
      target.version = model.get('version');
    }

    return new Patch({
      delta: modelDeltas.getDelta(model),
      target
    });
  },

  getDelta(model) {
    const differ = deltasLib.makeJSONDiffer();
    return differ.diff(_.omit(model._revertAttributes, deltasLib.DOC_SKIP_PATHS), _.omit(model.attributes, deltasLib.DOC_SKIP_PATHS));
  },

  getDeltaWith(model, otherModel) {
    const differ = deltasLib.makeJSONDiffer();
    return differ.diff(model.attributes, otherModel.attributes);
  },

  applyDelta(model, delta) {
    const newAttributes = $.extend(true, {}, model.attributes);
    try {
      jsondiffpatch.patch(newAttributes, delta);
    } catch (error) {
      if (!application.testing) {
        console.error('Error applying delta\n', JSON.stringify(delta, null, '\t'), '\n\nto attributes\n\n', newAttributes);
      }
      return false;
    }
    for (var key in newAttributes) {
      var value = newAttributes[key];
      if (_.isEqual(value, model.attributes[key])) { delete newAttributes[key]; }
    }

    model.set(newAttributes);
    return true;
  },

  getExpandedDelta(model) {
    const delta = modelDeltas.getDelta(model);
    return deltasLib.expandDelta(delta, model._revertAttributes, model.schema());
  },

  getExpandedDeltaWith(model, otherModel) {
    const delta = modelDeltas.getDeltaWith(model, otherModel);
    return deltasLib.expandDelta(delta, model.attributes, model.schema());
  }
});
