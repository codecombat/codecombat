// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let UserCodeProblem;
import CocoModel from './CocoModel';

export default UserCodeProblem = (function() {
  UserCodeProblem = class UserCodeProblem extends CocoModel {
    static initClass() {
      this.className = 'UserCodeProblem';
      this.schema = require('schemas/models/user_code_problem');
      this.prototype.urlRoot = '/db/user.code.problem';
    }
  };
  UserCodeProblem.initClass();
  return UserCodeProblem;
})();
