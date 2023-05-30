// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let Patches;
const PatchModel = require('models/Patch');
const CocoCollection = require('collections/CocoCollection');

module.exports = (Patches = (function() {
  Patches = class Patches extends CocoCollection {
    static initClass() {
      this.prototype.model = PatchModel;
    }

    fetchMineFor(targetModel, options) {
      if (options == null) { options = {}; }
      options.url = `${_.result(targetModel, 'url')}/patches`;
      if (options.data == null) { options.data = {}; }
      options.data.creator = me.id;
      return this.fetch(options);
    }
  };
  Patches.initClass();
  return Patches;
})());
