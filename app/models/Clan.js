// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let Clan;
import CocoModel from './CocoModel';
import schema from 'schemas/models/clan.schema';

export default Clan = (function() {
  Clan = class Clan extends CocoModel {
    static initClass() {
      this.className = 'Clan';
      this.schema = schema;
      this.prototype.urlRoot = '/db/clan';
    }
  };
  Clan.initClass();
  return Clan;
})();
