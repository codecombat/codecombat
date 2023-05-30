// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let RecentlyPlayedCollection;
import CocoCollection from './CocoCollection';
import LevelSession from 'models/LevelSession';

export default RecentlyPlayedCollection = (function() {
  RecentlyPlayedCollection = class RecentlyPlayedCollection extends CocoCollection {
    static initClass() {
      this.prototype.model = LevelSession;
    }

    constructor(userID, options) {
      this.url = `/db/user/${userID}/recently_played`;
      super(options);
    }
  };
  RecentlyPlayedCollection.initClass();
  return RecentlyPlayedCollection;
})();
