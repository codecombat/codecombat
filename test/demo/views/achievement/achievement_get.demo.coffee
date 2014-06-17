CocoModel = require 'models/CocoModel'
RootView = require 'views/kinds/RootView'
utils = require 'lib/utils'

class MockServer


module.exports = ->
  unlockable =
    name: 'Dungeon Arena Started'
    description: 'Started playing Dungeon Arena.'
    worth: 3
    collection: 'level.session'
    query: "{\"level.original\":\"dungeon-arena\"}"
    userField: 'creator'

  earnedUnlockable =
    earnedPoints: 3
    notified: false


  null
