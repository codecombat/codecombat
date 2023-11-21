// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ComponentVersionsModal;
const VersionsModal = require('views/editor/modal/VersionsModal');

module.exports = (ComponentVersionsModal = (function() {
  ComponentVersionsModal = class ComponentVersionsModal extends VersionsModal {
    static initClass() {
      this.prototype.id = 'editor-component-versions-view';
      this.prototype.url = '/db/level.component/';
      this.prototype.page = 'component';
    }

    constructor(options, ID) {
      super(options, this.ID, require('models/LevelComponent'));
      this.ID = ID;
    }
  };
  ComponentVersionsModal.initClass();
  return ComponentVersionsModal;
})());
