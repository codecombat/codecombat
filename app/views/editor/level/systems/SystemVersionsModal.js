// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let SystemVersionsModal;
const VersionsModal = require('views/editor/modal/VersionsModal');

module.exports = (SystemVersionsModal = (function() {
  SystemVersionsModal = class SystemVersionsModal extends VersionsModal {
    static initClass() {
      this.prototype.id = 'editor-system-versions-view';
      this.prototype.url = '/db/level.system/';
      this.prototype.page = 'system';
    }

    constructor(options, ID) {
      super(options, this.ID, require('models/LevelSystem'));
      this.ID = ID;
    }
  };
  SystemVersionsModal.initClass();
  return SystemVersionsModal;
})());
