/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let SimulatorsLeaderboardCollection;
const CocoCollection = require('collections/CocoCollection');
const User = require('models/User');

module.exports = (SimulatorsLeaderboardCollection = (function() {
  SimulatorsLeaderboardCollection = class SimulatorsLeaderboardCollection extends CocoCollection {
    static initClass() {
      this.prototype.url = '';
      this.prototype.model = User;
    }

    constructor(options) {
      super();
      if (options == null) { options = {}; }
      this.url = `/db/user/me/simulatorLeaderboard?${$.param(options)}`;
    }
  };
  SimulatorsLeaderboardCollection.initClass();
  return SimulatorsLeaderboardCollection;
})());
