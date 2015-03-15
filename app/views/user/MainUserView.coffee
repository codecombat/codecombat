UserView = require 'views/common/UserView'
CocoCollection = require 'collections/CocoCollection'
LevelSession = require 'models/LevelSession'
template = require 'templates/user/main-user-view'
{me} = require 'core/auth'
EarnedAchievementCollection = require 'collections/EarnedAchievementCollection'

class LevelSessionsCollection extends CocoCollection
  model: LevelSession

  constructor: (userID) ->
    @url = "/db/user/#{userID}/level.sessions?project=state.complete,levelID,levelName,changed,team,codeLanguage,submittedCodeLanguage,totalScore&order=-1"
    super()

module.exports = class MainUserView extends UserView
  id: 'user-home'
  template: template

  events:
    'click .more-button': 'onClickMoreButton'

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
        language = levelSession.get('codeLanguage') or levelSession.get('submittedCodeLanguage')
        if language
          languageCounts[language] = (languageCounts[language] or 0) + 1
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
      @supermodel.loadCollection @levelSessions, 'levelSessions', {cache: false}
      @supermodel.loadCollection @earnedAchievements, 'earnedAchievements', {cache: false}
    super()

  onClickMoreButton: (e) ->
    panel = $(e.target).closest('.panel')
    panel.find('tr.hide').removeClass('hide')
    panel.find('.panel-footer').remove()
