require('ozaria/site/styles/play/level/level-dialogue-view.sass')
CocoView = require 'views/core/CocoView'
template = require 'ozaria/site/templates/play/level/level-dialogue-view'

module.exports = class LevelDialogueView extends CocoView
  id: 'level-dialogue-view'
  template: template

  subscriptions:
    'sprite:speech-updated': 'onSpriteDialogue'

  events:
    'click': 'onClick'

  constructor: (options) ->
    super options
    @level = options.level
    @sessionID = options.sessionID

  onClick: (e) ->
    @addMoreMessage

  onSpriteDialogue: (e) ->
    if e.message
      $('.vega-dialogue').text(e.message)

  isFullScreen: ->
    document.fullScreen || document.mozFullScreen || document.webkitIsFullScreen

  addMoreMessage: =>
    console.log('inside addMoremessage')
    if @animator.done()
      clearInterval(@messageInterval)
      @messageInterval = null
      $('.enter', @bubble).removeClass('secret').css('opacity', 0.0).delay(500).animate({opacity: 1.0}, 500, @animateEnterButton)
      if @lastResponses
        buttons = $('.enter button')
        for response, i in @lastResponses
          channel = response.channel.replace 'level-set-playing', 'level:set-playing'  # Easier than migrating all those victory buttons.
          f = (r) => => setTimeout((-> Backbone.Mediator.publish(channel, r.event or {})), 10)
          $(buttons[i]).click(f(response))
      else
        $('.enter', @bubble).click(-> Backbone.Mediator.publish('script:end-current-script', {}))
      return
    @animator.tick()

  destroy: ->
    clearInterval(@messageInterval) if @messageInterval
    super()
