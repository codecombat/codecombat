UserView = require 'views/kinds/UserView'
template = require 'templates/user/achievements'
{me} = require 'lib/auth'
Achievement = require 'models/Achievement'
EarnedAchievement = require 'models/EarnedAchievement'
AchievementCollection = require 'collections/AchievementCollection'
EarnedAchievementCollection = require 'collections/EarnedAchievementCollection'

module.exports = class UserAchievementsView extends UserView
  id: 'user-achievements-view'
  template: template

  constructor: (options, userID) ->
    super options, userID

  onUserLoaded: (user) ->
    super user
    @achievements = @supermodel.loadCollection(new AchievementCollection, 'achievements').model
    @earnedAchievements = @supermodel.loadCollection(new EarnedAchievementCollection(@user), 'earnedAchievements').model

  onLoaded: ->
    console.log @earnedAchievements
    console.log 'onLoaded'
    _.each @earnedAchievements.models, (earned) =>
      console.log earned
      return unless relatedAchievement = _.find @achievements.models, (achievement) ->
        achievement.get('_id') is earned.get 'achievement'
      relatedAchievement.set 'unlocked', true
      earned.set 'achievement', relatedAchievement
    super()

  getRenderData: ->
    context = super()
    if @user and not @user.isAnonymous()
      context.achievements = @achievements.models
      context.earnedAchievements = @earnedAchievements.models
    context
