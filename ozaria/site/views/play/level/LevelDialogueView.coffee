require('ozaria/site/styles/play/level/level-dialogue-view.sass')
CocoView = require 'views/core/CocoView'
template = require 'ozaria/site/templates/play/level/level-dialogue-view'
marked = require 'marked'
fitty = require('fitty').default

resizeText = (text) ->
  minSize = 0
  length = text.length
  innerHeight = window.innerHeight
  innerWidth = window.innerWidth
  # Large size with big text
  if innerHeight >= 600 && innerWidth >= 1000
    if length < 65
      minSize = 26
    else if length < 128
      minSize = 20
    else
      minSize = 14
  # Small size - which is not handled well by our UI now anyway, but we'll do the best we can...
  else if innerHeight < 500 || innerWidth < 800
    if length < 65
      minSize = 8
    else if length < 128
      minSize = 6
    else
      minSize = 4
  # Any other combination of large/small width/height
  else
    if length < 65
      minSize = 16
    else if length < 128
      minSize = 12
    else
      minSize = 8

  fitty('.fit', {
    minSize
  })

  # To make the text break in a pretty way, we need to force the white-space to normal
  # because fitty wants it to expand to the maximum width. This needs to happen after
  # everything is done updating, and 50-100ms seems to work well. Setting it to 100ms
  # to give an extra little bit of time on lower end hardware.
  setTimeout(->
    $('.vega-dialogue').css('white-space', 'normal')
  , 100)


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
    # Resizing is debounced to avoid performance issues and spamming the text fitting.
    @onWindowResize = _.debounce(@onWindowResize, 100)
    $(window).on('resize', @onWindowResize)

  destroy: ->
    $(window).off('resize', @onWindowResize)
    super()

  onClick: (e) ->
    Backbone.Mediator.publish 'script:end-current-script', {}

  onWindowResize: (e) ->
    resizeText($('.vega-dialogue').text())

  onSpriteDialogue: (e) ->
    if e.message
      currentMessage = e.message.replace /&lt;i class=&#39;(.+?)&#39;&gt;&lt;\/i&gt;/, "<i class='$1'></i>"
      $('.vega-dialogue').html(marked(currentMessage))
      # The entire view is invisible until we have a message
      $('#level-dialogue-view')[0].style.display = 'flex'
      resizeText(currentMessage)

  isFullScreen: ->
    document.fullScreen || document.mozFullScreen || document.webkitIsFullScreen
