// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let LevelSystems;
import LevelSystem from 'models/LevelSystem';
import CocoCollection from 'collections/CocoCollection';

export default LevelSystems = (function() {
  LevelSystems = class LevelSystems extends CocoCollection {
    static initClass() {
      this.prototype.url = '/db/level.system';
      this.prototype.model = LevelSystem;
    }
  };
  LevelSystems.initClass();
  return LevelSystems;
})();
