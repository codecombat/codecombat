View = require 'views/kinds/RootView'
template = require 'templates/admin/level_sessions'
LevelSession = require 'models/LevelSession'

# Placeholder
class LevelSessionCollection extends Backbone.Collection
  url: '/db/level_session/x/active'
  model: LevelSession

module.exports = class LevelSessionsView extends View
  id: "admin-level-sessions-view"
  template: template

  constructor: (options) ->
    super options
    @getLevelSessions()

  getLevelSessions: ->
    @sessions = new LevelSessionCollection()
    @sessions.fetch()
    @listenToOnce @sessions, 'all', @render

  getRenderData: =>
    c = super()
    c.sessions = @sessions.models
    c.moment = moment
    c
