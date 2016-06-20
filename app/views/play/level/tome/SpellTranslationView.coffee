CocoView = require 'views/core/CocoView'
LevelComponent = require 'models/LevelComponent'
template = require 'templates/play/level/tome/spell_translation'
Range = ace.require('ace/range').Range
TokenIterator = ace.require('ace/token_iterator').TokenIterator
utils = require 'core/utils'

module.exports = class SpellTranslationView extends CocoView
  className: 'spell-translation-view'
  template: template
  
  events:
    'mousemove': ->
      @$el.hide()

  constructor: (options) ->
    super options
    @ace = options.ace
    @supermodel = options.supermodel
    
    levelComponents = @supermodel.getModels LevelComponent
    @componentTranslations = levelComponents.reduce((acc, lc) ->
      for doc in (lc.get('propertyDocumentation') ? [])
        translated = utils.i18n(doc, 'name', null, false)
        acc[doc.name] = translated if translated isnt doc.name
      acc
    , {})
    
    @onMouseMove = _.throttle @onMouseMove, 25
    
  afterRender: ->
    super()
    @ace.on 'mousemove', @onMouseMove

  setTooltipText: (text) =>
    @$el.find('code').text text
    @$el.show().css(@pos)
    
  isIdentifier: (t) ->
    t and (_.any([/identifier/, /keyword/], (regex) -> regex.test(t.type)) or t.value is 'this')
    
  onMouseMove: (e) =>
    return if @destroyed
    pos = e.getDocumentPosition()
    it = new TokenIterator e.editor.session, pos.row, pos.column
    endOfLine = it.getCurrentToken()?.index is it.$rowTokens.length - 1
    while it.getCurrentTokenRow() is pos.row and not @isIdentifier(token = it.getCurrentToken())
      break if endOfLine or not token  # Don't iterate beyond end or beginning of line
      it.stepBackward()
    unless @isIdentifier(token)
      @word = null
      @update()
      return
    try
      # Ace was breaking under some (?) conditions, dependent on mouse location.
      #   with $rowTokens = [] (but should have things)
      start = it.getCurrentTokenColumn()
    catch error
      start = 0
    end = start + token.value.length
    if @isIdentifier(token)
      @word = token.value
      @markerRange = new Range pos.row, start, pos.row, end
      @reposition(e.domEvent)
    @update()
    
  reposition: (e) ->
    offsetX = e.offsetX ? e.clientX - $(e.target).offset().left
    offsetY = e.offsetY ? e.clientY - $(e.target).offset().top
    w = $(document).width() - 20
    offsetX = w - $(e.target).offset().left - @$el.width() if e.clientX + @$el.width() > w
    @pos = {left: offsetX + 80, top: offsetY - 20}
    @$el.css(@pos)
    
  onMouseOut: ->
    @word = null
    @markerRange = null
    @update()
    
  update: ->
    i18nKey = 'code.'+@word
    translation = @componentTranslations[@word] or $.t(i18nKey)
    if @word and translation and translation not in [i18nKey, @word]
      @setTooltipText translation
    else
      @$el.hide()

  destroy: ->
    @ace?.removeEventListener 'mousemove', @onMouseMove
    super()
