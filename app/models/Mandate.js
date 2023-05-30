// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let MandateModel;
import CocoModel from './CocoModel';

export default MandateModel = (function() {
  MandateModel = class MandateModel extends CocoModel {
    static initClass() {
      this.className = 'Mandate';
      this.schema = require('schemas/models/mandate.schema');
      this.prototype.urlRoot = '/db/mandate';
    }
  };
  MandateModel.initClass();
  return MandateModel;
})();
