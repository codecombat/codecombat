// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ThangTypeVersionsModal;
import VersionsModal from 'views/editor/modal/VersionsModal';

export default ThangTypeVersionsModal = (function() {
  ThangTypeVersionsModal = class ThangTypeVersionsModal extends VersionsModal {
    static initClass() {
      this.prototype.id = 'editor-thang-versions-view';
      this.prototype.url = '/db/thang.type/';
      this.prototype.page = 'thang';
    }

    constructor(options, ID) {
      this.ID = ID;
      super(options, this.ID, require('models/ThangType'));
    }
  };
  ThangTypeVersionsModal.initClass();
  return ThangTypeVersionsModal;
})();
