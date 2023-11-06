// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS102: Remove unnecessary code created because of implicit returns
 * DS104: Avoid inline assignments
 * DS204: Change includes calls to have a more natural evaluation order
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let UserView;
const RootView = require('views/core/RootView');
const template = require('app/templates/common/user');
const User = require('models/User');

module.exports = (UserView = (function() {
  UserView = class UserView extends RootView {
    static initClass() {
      this.prototype.template = template;
      this.prototype.className = 'user-view';
      this.prototype.viewName = null;
       // Used for the breadcrumbs
    }

    constructor(userID, options) {
      super(options);
      this.userID = userID;
      this.listenTo(this, 'userNotFound', this.ifUserNotFound);
      this.fetchUser(this.userID);
    }

    fetchUser() {
      if (this.isMe()) {
        this.user = me;
        this.onLoaded();
      }
      this.user = new User({_id: this.userID});
      return this.supermodel.loadModel(this.user, {cache: false});
    }

    isMe() { let needle;
    return (needle = this.userID, [me.id, me.get('slug')].includes(needle)); }

    onLoaded() {
      if (!(this.user != null ? this.user.isAnonymous() : undefined)) { this.userData = this.user; }
      this.userID = this.user.id;
      return super.onLoaded();
    }

    ifUserNotFound() {
      console.warn('user not found');
      return this.render();
    }
  };
  UserView.initClass();
  return UserView;
})());
