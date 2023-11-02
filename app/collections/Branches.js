/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let Branches;
const CocoCollection = require('collections/CocoCollection');
const Branch = require('models/Branch');

module.exports = (Branches = (function() {
  Branches = class Branches extends CocoCollection {
    static initClass() {
      this.prototype.url = '/db/branches';
      this.prototype.model = Branch;
    }

    comparator(branch1, branch2) {
      const iUpdatedB1 = branch1.get('updatedBy') === me.id;
      const iUpdatedB2 = branch2.get('updatedBy') === me.id;
      if (iUpdatedB1 && !iUpdatedB2) { return -1; }
      if (iUpdatedB2 && !iUpdatedB1) { return 1; }
      return new Date(branch2.get('updated')).getTime() - new Date(branch1.get('updated')).getTime();
    }
  };
  Branches.initClass();
  return Branches;
})());
