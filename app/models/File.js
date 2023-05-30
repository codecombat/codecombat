// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let File;
import CocoModel from './CocoModel';

export default File = (function() {
  File = class File extends CocoModel {
    static initClass() {
      this.className = 'File';
      this.schema = {};
      this.prototype.urlRoot = '/db/file';
    }
  };
  File.initClass();
  return File;
})();
