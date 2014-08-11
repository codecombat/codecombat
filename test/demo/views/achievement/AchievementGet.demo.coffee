CocoModel = require 'models/CocoModel'
RootView = require 'views/kinds/RootView'
utils = require 'lib/utils'
Achievement = require 'models/Achievement'
EarnedAchievement = require 'models/EarnedAchievement'
fixtures = require '../../fixtures/achievements'

module.exports = ->
  me.set 'points', 48

  unlockableObj = fixtures.DungeonArenaStarted

  earnedUnlockableObj =
    earnedPoints: 3
    notified: false

  unlockable = new Achievement unlockableObj
  earnedUnlockable = new EarnedAchievement earnedUnlockableObj

  view = new RootView
  view.render()

  view.showNewAchievement unlockable, earnedUnlockable
  view
