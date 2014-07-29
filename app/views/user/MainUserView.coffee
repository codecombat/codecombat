UserView = require 'views/kinds/UserView'
CocoCollection = require 'collections/CocoCollection'
LevelSession = require 'models/LevelSession'
template = require 'templates/user/home'
{me} = require 'lib/auth'

class LevelSessionsCollection extends CocoCollection
  model: LevelSession

  constructor: (userID) ->
    @url = "/db/user/#{userID}/level.sessions?project=state.complete,levelID,levelName,changed,team,submittedCodeLanguage&order=-1"
    super()

module.exports = class MainUserView extends UserView
  id: 'user-home-view'
  template: template

  constructor: (userID, options) ->
    super options

  getRenderData: ->
    context = super()
    if @user
      singlePlayerSessions = []
      multiPlayerSessions = []
      languageCounts = {}
      for levelSession in @levelSessions.models
        if levelSession.isMultiPlayer()
          multiPlayerSessions.push levelSession
        else
          singlePlayerSessions.push levelSession
        languageCounts[levelSession.get 'submittedCodeLanguage'] = (languageCounts[levelSession.get 'submittedCodeLanguage'] or 0) + 1
      mostUsedCount = 0
      favoriteLanguage = null
      for language, count of languageCounts
        if count > mostUsedCount
          mostUsedCount = count
          favoriteLanguage = language
      context.singlePlayerSessions = singlePlayerSessions
      context.multiPlayerSessions = multiPlayerSessions
      context.favoriteLanguage = favoriteLanguage
    context

  onUserLoaded: (user) ->
    @levelSessions = @supermodel.loadCollection(new LevelSessionsCollection(@userID), 'levelSessions').model
    super user

  onLoaded: ->
    super()
