/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let RecentlyPlayedCollection;
const CocoCollection = require('./CocoCollection');
const LevelSession = require('models/LevelSession');

module.exports = (RecentlyPlayedCollection = (function() {
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
})());
