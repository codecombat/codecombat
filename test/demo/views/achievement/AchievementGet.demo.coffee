CocoModel = require 'models/CocoModel'
RootView = require 'views/kinds/RootView'
utils = require 'lib/utils'
Achievement = require 'models/Achievement'
EarnedAchievement = require 'models/EarnedAchievement'

class MockServer


module.exports = ->
  me.set 'points', 48

  unlockableObj =
    name: 'Dungeon Arena Started'
    description: 'Started playing Dungeon Arena. '
    worth: 3
    collection: 'level.session'
    query: "{\"level.original\":\"dungeon-arena\"}"
    userField: 'creator'

  earnedUnlockableObj =
    earnedPoints: 3
    notified: false

  unlockable = new Achievement unlockableObj
  earnedUnlockable = new EarnedAchievement earnedUnlockableObj

  console.log currentView
  data = currentView.createNotifyData unlockable, earnedUnlockable
  imageURL = '/images/achievements/swords-01.png'
  data.image = $("<img src='#{imageURL}' />")
  options =
    autoHideDelay: 10000
    globalPosition: 'bottom right'
    showDuration: 400
    style: 'achievement'
    autoHide: false
    clickToHide: false

  $.notify data, options
