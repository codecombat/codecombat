require('app/styles/play/level/surface-context-menu')
CocoView = require 'views/core/CocoView'

module.exports = class SurfaceContextMenuView extends CocoView
  id: 'surface-context-menu-view'
  className: 'surface-context-menu'
  template: require('templates/play/level/surface-context-menu')

  events:
    'click #copy': 'onClickCopy'

  subscriptions:
    'level:surface-context-menu-pressed': 'showView'
    'level:surface-context-menu-hide': 'hideView'
    
  constructor: (options) ->
    @supermodel = options.supermodel # Has to go before super so events are hooked up
    super options
    @level = options.level
    @session = options.session
    

  destroy: ->
    super()

  afterRender: ->
    super()

  onClickCopy: (e) ->
    if navigator.clipboard
      navigator.clipboard.writeText( @coordinates )
    else if document.queryCommandSupported('copy')
      textArea = document.createElement("textarea")
      textArea.value = @coordinates
      document.body.appendChild(textArea)
      textArea.focus()
      textArea.select()
      document.execCommand('copy')
      document.body.removeChild(textArea)
    else
      console.log "Copy Coordinates not supported"

  

  setPosition: (e) ->
    @$el.css('left', e.posX)
    @$el.css('top', e.posY)
    #margin = 20
    #width = @$levelInfo.outerWidth()
    #@$levelInfo.css('left', Math.min(Math.max(margin, mapX - width / 2), @$map.width() - width - margin))
    #height = @$levelInfo.outerHeight()
    #top = mapY - @$levelInfo.outerHeight() - 60
    #if top < 100
    #  top = mapY + 60
    #@$levelInfo.css('top', top)

  setCoordinates: (e) ->
    @coordinates = "#{e.wopX}, #{e.wopY}"
    message = "copy #{@coordinates}"
    @copyMessage = message

  hideView: ->
    @$el.hide()

  showView: (e) ->
    @$el.show()
    @setCoordinates(e)
    @setPosition(e)
    @render()