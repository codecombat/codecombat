UserView = require 'views/kinds/UserView'
CocoCollection = require 'collections/CocoCollection'
LevelSession = require 'models/LevelSession'
template = require 'templates/user/user_home'
{me} = require 'lib/auth'
EarnedAchievementCollection = require 'collections/EarnedAchievementCollection'

class LevelSessionsCollection extends CocoCollection
  model: LevelSession

  constructor: (userID) ->
    @url = "/db/user/#{userID}/level.sessions?project=state.complete,levelID,levelName,changed,team,submittedCodeLanguage,totalScore&order=-1"
    super()

module.exports = class MainUserView extends UserView
  id: 'user-home'
  template: template

  constructor: (userID, options) ->
    super options

  getRenderData: ->
    context = super()
    if @levelSessions and @levelSessions.loaded
      singlePlayerSessions = []
      multiPlayerSessions = []
      languageCounts = {}
      for levelSession in @levelSessions.models
        if levelSession.isMultiplayer()
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
    if @earnedAchievements and @earnedAchievements.loaded
      context.earnedAchievements = @earnedAchievements
    context

  onLoaded: ->
    if @user.loaded and not (@earnedAchievements or @levelSessions)
      @supermodel.resetProgress()
      @levelSessions = new LevelSessionsCollection @user.getSlugOrID()
      @earnedAchievements = new EarnedAchievementCollection @user.getSlugOrID()
      @supermodel.loadCollection @levelSessions, 'levelSessions'
      @supermodel.loadCollection @earnedAchievements, 'earnedAchievements'
    super()
