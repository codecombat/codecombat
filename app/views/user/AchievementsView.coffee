UserView = require 'views/kinds/UserView'
template = require 'templates/user/achievements'
{me} = require 'lib/auth'
Achievement = require 'models/Achievement'
EarnedAchievement = require 'models/EarnedAchievement'
AchievementCollection = require 'collections/AchievementCollection'
EarnedAchievementCollection = require 'collections/EarnedAchievementCollection'

module.exports = class AchievementsView extends UserView
  id: 'user-achievements-view'
  template: template
  viewName: 'Stats'
  activeLayout: 'grid'

  events:
    'click #grid-layout-button': 'layoutChanged'
    'click #table-layout-button': 'layoutChanged'

  constructor: (userID, options) ->
    super options, userID

  onUserLoaded: (user) ->
    @achievements = @supermodel.loadCollection(new AchievementCollection, 'achievements').model
    @earnedAchievements = @supermodel.loadCollection(new EarnedAchievementCollection(@user), 'earnedAchievements').model
    super user

  onLoaded: ->
    console.log @earnedAchievementsy
    console.log @achievements
    for earned in @earnedAchievements.models
      return unless relatedAchievement = _.find @achievements.models, (achievement) ->
        achievement.get('_id') is earned.get 'achievement'
      relatedAchievement.set 'unlocked', true
      earned.set 'achievement', relatedAchievement
    deferredImages = (achievement.cacheLockedImage() for achievement in @achievements.models when not achievement.get 'unlocked')
    whenever = $.when deferredImages...
    whenever.done => @render()
    super()

  layoutChanged: (e) ->
    @activeLayout = $(e.currentTarget).data 'layout'
    @render()

  getRenderData: ->
    context = super()
    context.activeLayout = @activeLayout

    # After user is loaded
    if @user and not @user.isAnonymous()
      context.earnedAchievements = @earnedAchievements.models
      context.achievements = @achievements.models
      context.achievementsByCategory = {}
      for achievement in @achievements.models
        context.achievementsByCategory[achievement.get('category')] ?= []
        context.achievementsByCategory[achievement.get('category')].push achievement
    context
