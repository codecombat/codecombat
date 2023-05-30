// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let SimulatorsLeaderboardCollection;
import CocoCollection from 'collections/CocoCollection';
import User from 'models/User';

export default SimulatorsLeaderboardCollection = (function() {
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
})();
