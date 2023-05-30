// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let CodeLog;
import CocoModel from './CocoModel';

export default CodeLog = (function() {
  CodeLog = class CodeLog extends CocoModel {
    static initClass() {
      this.className = 'CodeLog';
      this.schema = require('schemas/models/codelog.schema');
      this.prototype.urlRoot = '/db/codelogs';
    }
  };
  CodeLog.initClass();
  return CodeLog;
})();
