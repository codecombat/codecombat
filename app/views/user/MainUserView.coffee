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

  onLoaded: ->
    if @user.loaded
      if !@levelSessions
        @levelSessions = new LevelSessionsCollection @user.getSlugOrID()      
        @listenTo @levelSessions, 'sync', =>
          @onSyncLevelSessions @levelSessions?.models
          @render()
        @supermodel.loadCollection @levelSessions, 'levelSessions', {cache: false}

      if !@earnedAchievements
        @earnedAchievements = new EarnedAchievementCollection @user.getSlugOrID()
        @listenTo @earnedAchievements, 'sync', =>
          @render()
        @supermodel.loadCollection @earnedAchievements, 'earnedAchievements', {cache: false}

    sortClanList = (a, b) ->
      if a.get('members').length isnt b.get('members').length
        if a.get('members').length < b.get('members').length then 1 else -1
      else
        b.id.localeCompare(a.id)

    @clans = new CocoCollection([], { url: "/db/user/#{@userID}/clans", model: Clan, comparator: sortClanList })
    @listenTo @clans, 'sync', =>
      @onSyncClans @clans?.models
      @render?()
    @supermodel.loadCollection(@clans, 'clans', {cache: false})

    super()

  onSyncClans: (clans) ->
    return unless clans?
    @idNameMap = []
    @clanModels = clans
    options =
      url: '/db/user/-/names'
      method: 'POST'
      data: {ids: _.map(clans, (clan) -> clan.get('ownerID'))}
      success: (models, response, options) =>
        @idNameMap[userID] = models[userID].name for userID of models
        @render?()
    @supermodel.addRequestResource('user_names', options, 0).load()

  onSyncLevelSessions: (levelSessions) ->
    return unless levelSessions?
    @multiPlayerSessions = []
    @singlePlayerSessions = []
    languageCounts = []
    mostUsedCount = 0
    for levelSession in levelSessions
      if levelSession.isMultiplayer()
        @multiPlayerSessions.push levelSession
      else
        @singlePlayerSessions.push levelSession
      language = levelSession.get('codeLanguage') or levelSession.get('submittedCodeLanguage')
      if language
        languageCounts[language] = (languageCounts[language] or 0) + 1
    for language, count of languageCounts
      if count > mostUsedCount
        mostUsedCount = count
        @favoriteLanguage = language

  onClickMoreButton: (e) ->
    panel = $(e.target).closest('.panel')
    panel.find('tr.hide').removeClass('hide')
    panel.find('.panel-footer').remove()
