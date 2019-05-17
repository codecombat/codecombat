require('app/styles/play/level/play-web-dev-level-view.sass')
RootView = require 'views/core/RootView'

Level = require 'models/Level'
LevelSession = require 'models/LevelSession'
WebSurfaceView = require './WebSurfaceView'
api = require 'core/api'

require 'lib/game-libraries'
utils = require 'core/utils'

module.exports = class PlayWebDevLevelView extends RootView
  id: 'play-web-dev-level-view'
  template: require 'templates/play/level/play-web-dev-level-view'

  initialize: (@options, @sessionID) ->
    super(@options)

    @courseID = utils.getQueryVariable 'course'
    @session = @supermodel.loadModel(new LevelSession _id: @sessionID).model
    @level = new Level()
    @session.once 'sync', =>
      levelResource = @supermodel.addSomethingResource('level')
      api.levels.getByOriginal(@session.get('level').original).then (levelData) =>
        @levelID = levelData.slug
        @level.set({ _id: @levelID })
        @level.fetch()
        @level.once 'sync', =>
          levelResource.markLoaded()

          @setMeta({
            title: $.i18n.t 'play.web_development_title', { level: @level.get('name') }
          })

  getMeta: ->
    return {
      links: [
        { vmid: 'rel-canonical', rel: 'canonical', href: '/play'}
      ]
    }

  onLoaded: ->
    super()
    @insertSubView @webSurface = new WebSurfaceView {level: @level}
    Backbone.Mediator.publish 'tome:html-updated', html: @getHTML() ? '<h1>Player has no HTML</h1>', create: true
    @$el.find('#info-bar').delay(4000).fadeOut(2000)
    $('body').css('overflow', 'hidden')  # Don't show tiny scroll bar from our minimal additions to the iframe
    @eventProperties = {
      category: 'Play WebDev Level'
      @courseID
      sessionID: @session.id
      levelID: @level.id
      levelSlug: @level.get('slug')
    }
    window.tracker?.trackEvent 'Play WebDev Level - Load', @eventProperties


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
