// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let TournamentMatch;
const CocoModel = require('./CocoModel');

module.exports = (TournamentMatch = (function() {
  TournamentMatch = class TournamentMatch extends CocoModel {
    static initClass() {
      this.className = 'TournamentMatch';
      this.schema = require('schemas/models/tournament_match.schema');
      this.prototype.urlRoot = '/db/tournament.match';
    }
  };
  TournamentMatch.initClass();
  return TournamentMatch;
})());