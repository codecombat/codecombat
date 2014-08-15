CocoClass = require 'lib/CocoClass'
{me} = require 'lib/auth'
storage = require 'lib/storage'

module.exports = class GitHubHandler extends CocoClass
  scopes: 'user:email'

  subscriptions:
    'github-login': 'commenceGitHubLogin'

  constructor: ->
    super arguments...
    @clientID = if application.isProduction() then '9b405bf5fb84590d1f02' else 'fd5c9d34eb171131bc87'
    @redirect_uri = if application.isProduction() then 'http://codecombat.com/github/auth_callback' else 'http://localhost:3000/github/auth_callback'

  commenceGitHubLogin: ->
    request =
      scope: @scopes
      client_id: @clientID
      redirect_uri: @redirect_uri

    location.href = "https://github.com/login/oauth/authorize?" + $.param(request)
