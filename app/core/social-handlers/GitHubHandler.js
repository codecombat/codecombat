const CocoClass = require('core/CocoClass')
const { me } = require('core/auth')

class GitHubHandler extends CocoClass {
  constructor (application) {
    super()
    if (!me.useSocialSignOn()) {
      throw new Error('Social single sign on not supported')
    }
    this.scopes = 'user:email'
    this.subscriptions = {
      'auth:log-in-with-github': 'commenceGitHubLogin'
    }
    this.clientID = application.isProduction() ? '9b405bf5fb84590d1f02' : 'fd5c9d34eb171131bc87'
    this.redirectURI = application.isProduction() ? 'http://codecombat.com/github/auth_callback' : 'http://localhost:3000/github/auth_callback'
  }

  commenceGitHubLogin (e) {
    const request = {
      scope: this.scopes,
      client_id: this.clientID,
      redirect_uri: this.redirectURI
    }

    location.href = 'https://github.com/login/oauth/authorize?' + $.param(request)
  }
}

module.exports = GitHubHandler
