/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let LevelDialogueView;
require('ozaria/site/styles/play/level/level-dialogue-view.sass');
const CocoView = require('views/core/CocoView');
const template = require('app/templates/play/level/level-dialogue-view');

module.exports = (LevelDialogueView = (function() {
  LevelDialogueView = class LevelDialogueView extends CocoView {
    static initClass() {
      this.prototype.id = 'level-dialogue-view';
      this.prototype.template = template;
    }
  };
  LevelDialogueView.initClass();
  return LevelDialogueView;
})());
