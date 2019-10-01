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
    Backbone.Mediator.publish 'script:end-current-script', {}

  onSpriteDialogue: (e) ->
    if e.message
      currentMessage = e.message.replace /&lt;i class=&#39;(.+?)&#39;&gt;&lt;\/i&gt;/, "<i class='$1'></i>"
      $('.vega-dialogue').text(currentMessage)
      # The entire view is invisible until we have a message
      $('#level-dialogue-view')[0].style.display = 'flex'

  isFullScreen: ->
    document.fullScreen || document.mozFullScreen || document.webkitIsFullScreen
