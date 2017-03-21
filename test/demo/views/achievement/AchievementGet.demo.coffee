CocoModel = require 'models/CocoModel'
RootView = require 'views/core/RootView'
utils = require 'core/utils'
Achievement = require 'models/Achievement'
EarnedAchievement = require 'models/EarnedAchievement'
fixtures = require '../../fixtures/achievements'

module.exports = ->
  me.set 'points', 48
  me.set 'preferredLanguage', 'es'

  unlockableObj = fixtures.DungeonArenaStarted
  earnedUnlockableObj =
    earnedPoints: 3
    notified: false
  simulated = fixtures.Simulated
  earnedSimulated =
    achievedAmount: 1
    earnedPoints: 1
    notified: false


  unlockable = new Achievement unlockableObj
  earnedUnlockable = new EarnedAchievement earnedUnlockableObj
  simulated = new Achievement simulated
  earnedSimulated = new EarnedAchievement earnedSimulated

  view = new RootView
  view.render()

  view.showNewAchievement unlockable, earnedUnlockable
  #view.showNewAchievement simulated, earnedSimulated
  view
