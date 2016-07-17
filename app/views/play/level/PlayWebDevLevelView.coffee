RootView = require 'views/core/RootView'

Level = require 'models/Level'
LevelSession = require 'models/LevelSession'
WebSurfaceView = require './WebSurfaceView'

module.exports = class PlayWebDevLevelView extends RootView
  id: 'play-web-dev-level-view'
  template: require 'templates/play/level/play-web-dev-level-view'

  initialize: (@options, @levelID, @sessionID) ->
    @courseID = @getQueryVariable 'course'
    @level = @supermodel.loadModel(new Level _id: @levelID).model
    @session = @supermodel.loadModel(new LevelSession _id: @sessionID).model

  onLoaded: ->
    super()
    @insertSubView @webSurface = new WebSurfaceView {level: @level}
    Backbone.Mediator.publish 'tome:html-updated', html: @getHTML() ? '<h1>Player has no HTML</h1>', create: true
    @$el.find('#info-bar').delay(4000).fadeOut(2000)
    $('body').css('overflow', 'hidden')  # Don't show tiny scroll bar from our minimal additions to the iframe

  showError: (jqxhr) ->
    $('h1').text jqxhr.statusText

  getHTML: ->
    playerHTML = @session.get('code')?['hero-placeholder']?.plan
    return playerHTML unless hero = _.find @level.get('thangs'), id: 'Hero Placeholder'
    return playerHTML unless programmableConfig = _.find(hero.components, (component) -> component.config?.programmableMethods).config
    return programmableConfig.programmableMethods.plan.languages.html.replace /<playercode>[\s\S]*<\/playercode>/, playerHTML

  destroy: ->
    @webSurface?.destroy()
    $('body').css('overflow', 'initial')  # Recover from our modifications to body overflow before we leave
    super()
