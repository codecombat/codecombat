// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let LeaderboardCollection;
const CocoCollection = require('collections/CocoCollection');
const LevelSession = require('models/LevelSession');

module.exports = (LeaderboardCollection = (function() {
  LeaderboardCollection = class LeaderboardCollection extends CocoCollection {
    static initClass() {
      this.prototype.url = '';
      this.prototype.model = LevelSession;
    }

    constructor(level, options) {
      super();
      if (options == null) { options = {}; }
      this.url = `/db/level/${level.get('original')}/rankings?${$.param(options)}`;
    }
  };
  LeaderboardCollection.initClass();
  return LeaderboardCollection;
})());
