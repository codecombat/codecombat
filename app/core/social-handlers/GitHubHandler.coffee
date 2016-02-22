CocoClass = require 'core/CocoClass'
{me} = require 'core/auth'
storage = require 'core/storage'

module.exports = class GitHubHandler extends CocoClass
  scopes: 'user:email'

  subscriptions:
    'auth:log-in-with-github': 'commenceGitHubLogin'

  constructor: ->
    super arguments...
    @clientID = if application.isProduction() then '9b405bf5fb84590d1f02' else 'fd5c9d34eb171131bc87'
    @redirectURI = if application.isProduction() then 'http://codecombat.com/github/auth_callback' else 'http://localhost:3000/github/auth_callback'

  commenceGitHubLogin: (e) ->
    request =
      scope: @scopes
      client_id: @clientID
      redirect_uri: @redirectURI

    location.href = "https://github.com/login/oauth/authorize?" + $.param(request)