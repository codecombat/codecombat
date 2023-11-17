// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let TournamentSubmission;
const CocoModel = require('./CocoModel');

module.exports = (TournamentSubmission = (function() {
  TournamentSubmission = class TournamentSubmission extends CocoModel {
    static initClass() {
      this.className = 'TournamentSubmission';
      this.schema = require('schemas/models/tournament_submission.schema');
      this.prototype.urlRoot = '/db/tournament.submission';
    }
  };
  TournamentSubmission.initClass();
  return TournamentSubmission;
})());
