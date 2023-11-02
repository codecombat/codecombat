/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let GitHubHandler;
const CocoClass = require('core/CocoClass');
const {me} = require('core/auth');
const storage = require('core/storage');

module.exports = (GitHubHandler = (function() {
  GitHubHandler = class GitHubHandler extends CocoClass {
    static initClass() {
      this.prototype.scopes = 'user:email';
  
      this.prototype.subscriptions =
        {'auth:log-in-with-github': 'commenceGitHubLogin'};
    }

    constructor(application) {
      if (!me.useSocialSignOn()) { throw new Error('Social single sign on not supported'); }
      super(...arguments);
      this.clientID = application.isProduction() ? '9b405bf5fb84590d1f02' : 'fd5c9d34eb171131bc87';
      this.redirectURI = application.isProduction() ? 'http://codecombat.com/github/auth_callback' : 'http://localhost:3000/github/auth_callback';
    }

    commenceGitHubLogin(e) {
      const request = {
        scope: this.scopes,
        client_id: this.clientID,
        redirect_uri: this.redirectURI
      };

      return location.href = "https://github.com/login/oauth/authorize?" + $.param(request);
    }
  };
  GitHubHandler.initClass();
  return GitHubHandler;
})());
