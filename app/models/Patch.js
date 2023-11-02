// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let PatchModel;
const CocoModel = require('./CocoModel');

module.exports = (PatchModel = (function() {
  PatchModel = class PatchModel extends CocoModel {
    static initClass() {
      this.className = 'Patch';
      this.schema = require('schemas/models/patch');
      this.prototype.urlRoot = '/db/patch';
    }

    setStatus(status, options) {
      if (options == null) { options = {}; }
      options.url = `/db/patch/${this.id}/status`;
      options.type = 'PUT';
      return this.save({status}, options);
    }

    static setStatus(id, status) {
      return $.ajax(`/db/patch/${id}/status`, {type: 'PUT', data: {status}});
    }
  };
  PatchModel.initClass();
  return PatchModel;
})());
