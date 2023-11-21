// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let LevelComponents;
const LevelComponent = require('models/LevelComponent');
const CocoCollection = require('collections/CocoCollection');

module.exports = (LevelComponents = (function() {
  LevelComponents = class LevelComponents extends CocoCollection {
    static initClass() {
      this.prototype.url = '/db/level.component';
      this.prototype.model = LevelComponent;
    }
  };
  LevelComponents.initClass();
  return LevelComponents;
})());
