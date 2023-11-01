/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let UserCodeProblem;
const CocoModel = require('./CocoModel');

module.exports = (UserCodeProblem = (function() {
  UserCodeProblem = class UserCodeProblem extends CocoModel {
    static initClass() {
      this.className = 'UserCodeProblem';
      this.schema = require('schemas/models/user_code_problem');
      this.prototype.urlRoot = '/db/user.code.problem';
    }
  };
  UserCodeProblem.initClass();
  return UserCodeProblem;
})());
