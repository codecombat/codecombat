/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let LevelVersionsModal;
const VersionsModal = require('views/editor/modal/VersionsModal');

module.exports = (LevelVersionsModal = (function() {
  LevelVersionsModal = class LevelVersionsModal extends VersionsModal {
    static initClass() {
      this.prototype.id = 'editor-level-versions-view';
      this.prototype.url = '/db/level/';
      this.prototype.page = 'level';
    }

    constructor(options, ID) {
      this.ID = ID;
      super(options, this.ID, require('models/Level'));
    }
  };
  LevelVersionsModal.initClass();
  return LevelVersionsModal;
})());
