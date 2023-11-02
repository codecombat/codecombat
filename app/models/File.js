/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let File;
const CocoModel = require('./CocoModel');

module.exports = (File = (function() {
  File = class File extends CocoModel {
    static initClass() {
      this.className = 'File';
      this.schema = {};
      this.prototype.urlRoot = '/db/file';
    }
  };
  File.initClass();
  return File;
})());
