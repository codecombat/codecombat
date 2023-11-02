/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let UserPollsRecord;
const CocoModel = require('./CocoModel');
const schema = require('schemas/models/user-polls-record.schema');

module.exports = (UserPollsRecord = (function() {
  UserPollsRecord = class UserPollsRecord extends CocoModel {
    static initClass() {
      this.className = 'UserPollsRecord';
      this.schema = schema;
      this.prototype.urlRoot = '/db/user.polls.record';
    }
  };
  UserPollsRecord.initClass();
  return UserPollsRecord;
})());
