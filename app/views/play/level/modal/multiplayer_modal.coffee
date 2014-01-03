View = require 'views/kinds/ModalView'
template = require 'templates/play/level/modal/multiplayer'

module.exports = class MultiplayerModal extends View
  id: 'level-multiplayer-modal'
  template: template

  events:
    'click textarea': 'onClickLink'
    'change #multiplayer': 'updateLinkSection'
  
  constructor: (options) ->
    super(options)
    @session = options.session
    @session.on 'change:multiplayer', @updateLinkSection

  getRenderData: ->
    c = super()
    c.joinLink = (document.location.href.replace(/\?.*/, '').replace('#', '') +
      '?session=' +
      @session.id)
    c.multiplayer = @session.get('multiplayer')
    c
  
  afterRender: ->
    super()
    @updateLinkSection()
    
  onClickLink: (e) =>
    e.target.select()
    
  updateLinkSection: =>
    multiplayer = @$el.find('#multiplayer').attr('checked')
    la = @$el.find('#link-area')
    if multiplayer then la.show() else la.hide()

  onHidden: ->
    multiplayer = Boolean(@$el.find('#multiplayer').attr('checked'))
    @session.set('multiplayer', multiplayer)