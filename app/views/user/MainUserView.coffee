UserView = require 'views/common/UserView'
CocoCollection = require 'collections/CocoCollection'
LevelSession = require 'models/LevelSession'
template = require 'templates/user/main-user-view'
{me} = require 'core/auth'
Clan = require 'models/Clan'
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

  destroy: ->
    @stopListening?()

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
      context.playerLevel = @user.level()
    if @earnedAchievements and @earnedAchievements.loaded
      context.earnedAchievements = @earnedAchievements
    if @clans and @clans.loaded
      context.clans = @clans.models
      context.idNameMap = @idNameMap
    context

  onLoaded: ->
    if @user.loaded and not (@earnedAchievements or @levelSessions)
      @supermodel.resetProgress()
      @levelSessions = new LevelSessionsCollection @user.getSlugOrID()
      @earnedAchievements = new EarnedAchievementCollection @user.getSlugOrID()
      @supermodel.loadCollection @levelSessions, 'levelSessions', {cache: false}
      @supermodel.loadCollection @earnedAchievements, 'earnedAchievements', {cache: false}
    sortClanList = (a, b) ->
      if a.get('members').length isnt b.get('members').length
        if a.get('members').length < b.get('members').length then 1 else -1
      else
        b.id.localeCompare(a.id)
    @idNameMap = {}
    @clans = new CocoCollection([], { url: "/db/user/#{@userID}/clans", model: Clan, comparator: sortClanList })
    @listenTo @clans, 'sync', =>
      @refreshNameMap @clans?.models
      @render?()
    @supermodel.loadCollection(@clans, 'clans', {cache: false})
    super()

  refreshNameMap: (clans) ->
    return unless clans?
    options =
      url: '/db/user/-/names'
      method: 'POST'
      data: {ids: _.map(clans, (clan) -> clan.get('ownerID'))}
      success: (models, response, options) =>
        @idNameMap[userID] = models[userID].name for userID of models
        @render?()
    @supermodel.addRequestResource('user_names', options, 0).load()

  onClickMoreButton: (e) ->
    panel = $(e.target).closest('.panel')
    panel.find('tr.hide').removeClass('hide')
    panel.find('.panel-footer').remove()
