LevelSessionCodeView = require 'views/common/LevelSessionCodeView'
LevelSession = require 'models/LevelSession'

levelSessionData = require './level-session.fixture'
levelData = require './level.fixture';

module.exports = ->
  session = new LevelSession(levelSessionData)
  v = new LevelSessionCodeView({session:session})
  request = jasmine.Ajax.requests.mostRecent()
  request.respondWith({status: 200, responseText: JSON.stringify(levelData)})
  v.render()
  v
