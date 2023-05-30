// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let LevelComponents;
import LevelComponent from 'models/LevelComponent';
import CocoCollection from 'collections/CocoCollection';

export default LevelComponents = (function() {
  LevelComponents = class LevelComponents extends CocoCollection {
    static initClass() {
      this.prototype.url = '/db/level.component';
      this.prototype.model = LevelComponent;
    }
  };
  LevelComponents.initClass();
  return LevelComponents;
})();
