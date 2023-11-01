/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let LevelFeedback;
const CocoModel = require('./CocoModel');

module.exports = (LevelFeedback = (function() {
  LevelFeedback = class LevelFeedback extends CocoModel {
    static initClass() {
      this.className = 'LevelFeedback';
      this.schema = require('schemas/models/level_feedback');
      this.prototype.urlRoot = '/db/level.feedback';
    }
  };
  LevelFeedback.initClass();
  return LevelFeedback;
})());
