RootView = require 'views/core/RootView'
template = require 'templates/admin/level_sessions'
LevelSession = require 'models/LevelSession'
CocoCollection = require 'collections/CocoCollection'

class LevelSessionCollection extends CocoCollection
  url: '/db/level_session/x/active?project=screenshot,levelName,creatorName'
  model: LevelSession

module.exports = class LevelSessionsView extends RootView
  id: 'admin-level-sessions-view'
  template: template

  constructor: (options) ->
    super options
    @getLevelSessions()

  getLevelSessions: ->
    @sessions = @supermodel.loadCollection(new LevelSessionCollection(), 'sessions', {cache: false}).model

  getRenderData: =>
    c = super()
    c.sessions = @sessions.models
    c.moment = moment
    c
