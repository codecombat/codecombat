// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let Branch;
import CocoModel from './CocoModel';
import schema from 'schemas/models/branch.schema';
import CocoCollection from 'collections/CocoCollection';

export default Branch = (function() {
  Branch = class Branch extends CocoModel {
    static initClass() {
      this.className = 'Branch';
      this.schema = schema;
      this.prototype.urlRoot = '/db/branches';
    }
  };
  Branch.initClass();
  return Branch;
})();
