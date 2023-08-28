WorldSelectModal = require './modals/WorldSelectModal'
ThangType = require 'models/ThangType'
AIChatMessage = require 'models/AIChatMessage'
AIScenario = require 'models/AIScenario'
AIProject = require 'models/AIProject'
LevelComponent = require 'models/LevelComponent'
CocoCollection = require 'collections/CocoCollection'
entities = require 'entities'
require 'lib/setupTreema'
require('vendor/scripts/jquery-ui-1.11.1.custom')
require('vendor/styles/jquery-ui-1.11.1.custom.css')
utils = require('core/utils')

makeButton = -> $('<a class="btn btn-primary btn-xs treema-map-button"><span class="glyphicon glyphicon-screenshot"></span></a>')
shorten = (f) -> parseFloat(f.toFixed(1))
WIDTH = 924

module.exports.WorldPointNode = class WorldPointNode extends TreemaNode.nodeMap.point2d
  constructor: (args...) ->
    super(args...)
    console.error 'Point Treema node needs a World included in the settings.' unless @settings.world?
    console.error 'Point Treema node needs a RootView included in the settings.' unless @settings.view?

  buildValueForDisplay: (valEl, data) ->
    super(valEl, data)
    valEl.find('.treema-shortened').prepend(makeButton())

  buildValueForEditing: (valEl, data) ->
    super(valEl, data)
    valEl.find('.treema-shortened').prepend(makeButton())

  onClick: (e) ->
    btn = $(e.target).closest('.treema-map-button')
    if btn.length then @openMap() else super(arguments...)

  openMap: ->
    modal = new WorldSelectModal(world: @settings.world, dataType: 'point', default: @getData(), supermodel: @settings.supermodel)
    modal.callback = @callback
    @settings.view.openModalView modal

  callback: (e) =>
    return unless e?.point?
    @data.x = shorten(e.point.x)
    @data.y = shorten(e.point.y)
    @refreshDisplay()

class WorldRegionNode extends TreemaNode.nodeMap.object
  # this class is not yet used, later will be used to configure the Physical component

  constructor: (args...) ->
    super(args...)
    console.error 'Region Treema node needs a World included in the settings.' unless @settings.world?
    console.error 'Region Treema node needs a RootView included in the settings.' unless @settings.view?

  buildValueForDisplay: (valEl, data) ->
    super(valEl, data)
    valEl.find('.treema-shortened').prepend(makeButton())

  buildValueForEditing: (valEl, data) ->
    super(valEl, data)
    valEl.find('.treema-shortened').prepend(makeButton())

  onClick: (e) ->
    btn = $(e.target).closest('.treema-map-button')
    if btn.length then @openMap() else super(arguments...)

  openMap: ->
    modal = new WorldSelectModal(world: @settings.world, dataType: 'region', default: @createWorldBounds(), supermodel: @settings.supermodel)
    modal.callback = @callback
    @settings.view.openModalView modal

  callback: (e) =>
    x = Math.min e.points[0].x, e.points[1].x
    y = Math.min e.points[0].y, e.points[1].y
    @data.pos = {x: x, y: y, z: 0}
    @data.width = Math.abs e.points[0].x - e.points[1].x
    @data.height = Math.min e.points[0].y - e.points[1].y
    @refreshDisplay()

  createWorldBounds: ->
    # not yet written

module.exports.WorldViewportNode = class WorldViewportNode extends TreemaNode.nodeMap.object
  # selecting ratio'd dimensions in the world, ie the camera in level scripts
  constructor: (args...) ->
    super(args...)
    console.error 'Viewport Treema node needs a World included in the settings.' unless @settings.world?
    console.error 'Viewport Treema node needs a RootView included in the settings.' unless @settings.view?

  buildValueForDisplay: (valEl, data) ->
    super(valEl, data)
    valEl.find('.treema-shortened').prepend(makeButton())

  buildValueForEditing: (valEl, data) ->
    super(valEl, data)
    valEl.find('.treema-shortened').prepend(makeButton())

  onClick: (e) ->
    btn = $(e.target).closest('.treema-map-button')
    if btn.length then @openMap() else super(arguments...)

  openMap: ->
    # can't really get the bounds from this data, so will have to hack this solution
    options = world: @settings.world, dataType: 'ratio-region'
    data = @getData()
    options.defaultFromZoom = data if data?.target?.x?
    options.supermodel = @settings.supermodel
    modal = new WorldSelectModal(options)
    modal.callback = @callback
    @settings.view.openModalView modal

  callback: (e) =>
    return unless e
    target = {
      x: shorten((e.points[0].x + e.points[1].x) / 2)
      y: shorten((e.points[0].y + e.points[1].y) / 2)
    }
    @set('target', target)
    bounds = e.camera.normalizeBounds(e.points)
    @set('zoom', shorten(WIDTH / bounds.width))
    @refreshDisplay()

module.exports.WorldBoundsNode = class WorldBoundsNode extends TreemaNode.nodeMap.array
  # selecting camera boundaries for a world
  dataType: 'region'

  constructor: (args...) ->
    super(args...)
    console.error 'Bounds Treema node needs a World included in the settings.' unless @settings.world?
    console.error 'Bounds Treema node needs a RootView included in the settings.' unless @settings.view?

  buildValueForDisplay: (valEl, data) ->
    super(valEl, data)
    valEl.find('.treema-shortened').prepend(makeButton())

  buildValueForEditing: (valEl, data) ->
    super(valEl, data)
    valEl.find('.treema-shortened').prepend(makeButton())

  onClick: (e) ->
    btn = $(e.target).closest('.treema-map-button')
    if btn.length then @openMap() else super(arguments...)

  openMap: ->
    bounds = @getData() or [{x: 0, y: 0}, {x: 100, y: 80}]
    modal = new WorldSelectModal(world: @settings.world, dataType: 'region', default: bounds, supermodel: @settings.supermodel)
    modal.callback = @callback
    @settings.view.openModalView modal

  callback: (e) =>
    return unless e
    @set '/0', {x: shorten(e.points[0].x), y: shorten(e.points[0].y)}
    @set '/1', {x: shorten(e.points[1].x), y: shorten(e.points[1].y)}

module.exports.ThangNode = class ThangNode extends TreemaNode.nodeMap.string
  buildValueForDisplay: (valEl, data) ->
    super(valEl, data)
    valEl.find('input').autocomplete(source: @settings.thangIDs, minLength: 0, delay: 0, autoFocus: true)
    valEl

module.exports.TeamNode = class TeamNode extends TreemaNode.nodeMap.string
  buildValueForDisplay: (valEl, data) ->
    super(valEl, data)
    valEl.find('input').autocomplete(source: @settings.teams, minLength: 0, delay: 0, autoFocus: true)
    valEl

module.exports.SuperteamNode = class SuperteamNode extends TreemaNode.nodeMap.string
  buildValueForEditing: (valEl, data) ->
    super(valEl, data)
    valEl.find('input').autocomplete(source: @settings.superteams, minLength: 0, delay: 0, autoFocus: true)
    valEl

module.exports.RadiansNode = class RadiansNode extends TreemaNode.nodeMap.number
  buildValueForDisplay: (valEl, data) ->
    super(valEl, data)
    deg = data / Math.PI * 180
    valEl.text valEl.text() + "rad (#{deg.toFixed(0)}˚)"

module.exports.MetersNode = class MetersNode extends TreemaNode.nodeMap.number
  buildValueForDisplay: (valEl, data) ->
    super(valEl, data)
    valEl.text valEl.text() + 'm'

module.exports.KilogramsNode = class KilogramsNode extends TreemaNode.nodeMap.number
  buildValueForDisplay: (valEl, data) ->
    super(valEl, data)
    valEl.text valEl.text() + 'kg'

module.exports.SecondsNode = class SecondsNode extends TreemaNode.nodeMap.number
  buildValueForDisplay: (valEl, data) ->
    super(valEl, data)
    valEl.text valEl.text() + 's'

module.exports.MillisecondsNode = class MillisecondsNode extends TreemaNode.nodeMap.number
  buildValueForDisplay: (valEl, data) ->
    super(valEl, data)
    valEl.text valEl.text() + 'ms'

module.exports.SpeedNode = class SpeedNode extends TreemaNode.nodeMap.number
  buildValueForDisplay: (valEl, data) ->
    super(valEl, data)
    valEl.text valEl.text() + 'm/s'

module.exports.AccelerationNode = class AccelerationNode extends TreemaNode.nodeMap.number
  buildValueForDisplay: (valEl, data) ->
    super(valEl, data)
    valEl.text valEl.text() + 'm/s^2'

module.exports.ThangTypeNode = class ThangTypeNode extends TreemaNode.nodeMap.string
  valueClass: 'treema-thang-type'
  @thangTypes: null
  @thangTypesCollection: null

  constructor: (args...) ->
    super args...
    data = @getData()
    @thangType = _.find @settings.supermodel.getModels(ThangType), (m) => m.get('original') is data if data

  buildValueForDisplay: (valEl) ->
    @buildValueForDisplaySimply(valEl, @thangType?.get('name') or 'None')

  buildValueForEditing: (valEl, data) ->
    super(valEl, data)
    thangTypeNames = (m.get('name') for m in @settings.supermodel.getModels ThangType)
    input = valEl.find('input').autocomplete(source: thangTypeNames, minLength: 0, delay: 0, autoFocus: true)
    input.val(@thangType?.get('name') or 'None')
    valEl

  saveChanges: ->
    thangTypeName = @$el.find('input').val()
    @thangType = _.find @settings.supermodel.getModels(ThangType), (m) -> m.get('name') is thangTypeName
    if @thangType
      @data = @thangType.get('original')
    else
      @data = null

module.exports.ThangTypeNode = ThangTypeNode = class ThangTypeNode extends TreemaNode.nodeMap.string
  valueClass: 'treema-thang-type'
  @thangTypesCollection: null  # Lives in ThangTypeNode parent class
  @thangTypes: null  # Lives in ThangTypeNode or subclasses

  constructor: ->
    super(arguments...)
    @getThangTypes()
    unless ThangTypeNode.thangTypesCollection.loaded
      f = -> 
        @refreshDisplay() unless @isEditing()
        @getThangTypes()
      ThangTypeNode.thangTypesCollection.once('sync', f, @)

  buildValueForDisplay: (valEl, data) ->
    @buildValueForDisplaySimply(valEl, @getCurrentThangType() or '')
    valEl

  buildValueForEditing: (valEl, data) ->
    super(valEl, data)
    input = valEl.find 'input'
    source = (req, res) =>
      { term } = req
      term = term.toLowerCase()
      return res([]) unless @constructor.thangTypes
      return res(thangType.name for thangType in @constructor.thangTypes when _.string.contains(thangType.name.toLowerCase(), term))
    input.autocomplete(source: source, minLength: 0, delay: 0, autoFocus: true)
    input.val(@getCurrentThangType() or '')
    valEl

  filterThangType: (thangType) -> true

  getCurrentThangType: ->
    return null unless @constructor.thangTypes
    return null unless original = @getData()
    thangType = _.find @constructor.thangTypes, { original: original }
    thangType?.name or '...'

  getThangTypes: ->
    if ThangTypeNode.thangTypesCollection
      if not @constructor.thangTypes
        @processThangTypes(ThangTypeNode.thangTypesCollection)
      return
    ThangTypeNode.thangTypesCollection = new CocoCollection([], {
      url: '/db/thang.type'
      project:['name', 'components', 'original']
      model: ThangType
    })
    res = ThangTypeNode.thangTypesCollection.fetch()
    ThangTypeNode.thangTypesCollection.once 'sync', => @processThangTypes(ThangTypeNode.thangTypesCollection)

  processThangTypes: (thangTypeCollection) ->
    @constructor.thangTypes = []
    @processThangType thangType for thangType in thangTypeCollection.models

  processThangType: (thangType) ->
    @constructor.thangTypes.push name: thangType.get('name'), original: thangType.get('original')

  saveChanges: ->
    thangTypeName = @$el.find('input').val()
    thangType = _.find(@constructor.thangTypes, {name: thangTypeName})
    return @remove() unless thangType
    @data = thangType.original

module.exports.ItemThangTypeNode = ItemThangTypeNode = class ItemThangTypeNode extends ThangTypeNode
  valueClass: 'treema-item-thang-type'

  filterThangType: (thangType) ->
    @keyForParent in thangType.slots

  processThangType: (thangType) ->
    return unless itemComponent = _.find thangType.get('components'), {original: LevelComponent.ItemID}
    @constructor.thangTypes.push name: thangType.get('name'), original: thangType.get('original'), slots: itemComponent.config?.slots ? ['right-hand']

module.exports.ChatMessageLinkNode = ChatMessageLinkNode = class ChatMessageLinkNode extends TreemaNode.nodeMap.string
  buildValueForDisplay: (valEl, data) ->
    super valEl, data

    @$el.find('.ai-chat-message-link').remove()
    @$el.find('.treema-row').prepend $("<span class='ai-chat-message-link'><a href='/editor/ai-chat-message/#{data}' target='_blank' title='Edit'>(e)</a>&nbsp;</span>")

    chatMessageCollection = new CocoCollection([], {
      url: '/db/ai_chat_message'
      project:['actor', 'text']
      model: AIChatMessage
    })
    res = chatMessageCollection.fetch({url: "/db/ai_chat_message/#{data}"})
    chatMessageCollection.once 'sync', => @processChatMessages(chatMessageCollection)

  processChatMessages: (chatMessageCollection) ->
    text = chatMessageCollection.models?[0]?.get('text')
    if text
      htmlText = entities.decodeHTML(text.substring(0, 60)); 
      @$el.find('.ai-chat-message-link-text').remove()
      @$el.find('.treema-row').append $("<span class='ai-chat-message-link-text'></span>").text(htmlText)

    actor = chatMessageCollection.models?[0]?.get('actor')
    if actor
      @$el.find('.ai-chat-message-actor').remove()
      @$el.find('.treema-row').append $("<span class='ai-chat-message-actor'>&nbsp;<sub>actor:</sub> #{actor}&nbsp;</span>")
      
module.exports.ChatMessageParentLinkNode = ChatMessageParentLinkNode = class ChatMessageParentLinkNode extends TreemaNode.nodeMap.string
  buildValueForDisplay: (valEl, data) ->
    super valEl, data
    return unless data

    parentKind = @parent.data.parentKind

    return unless parentKind;

    @$el.find('.ai-chat-message-link').remove()
    @$el.find('.treema-row').prepend $("<span class='ai-chat-message-link'><a href='/editor/ai-#{parentKind}/#{data}' title='Edit' target='_blank'>(e)</a>&nbsp;</span>")

    parentCollection = new CocoCollection([], {
      url: "/db/ai_#{parentKind}"
      project:['name']
      model: if parentKind is 'project' then AIProject else AIScenario
    })
    res = parentCollection.fetch({url: "/db/ai_#{parentKind}/#{data}"})
    parentCollection.once 'sync', => @processParent(parentCollection)

  processParent: (parentCollection) ->
    text = parentCollection.models?[0]?.get('name')
    if text
      htmlText = entities.decodeHTML(text.substring(0, 60)); 
      @$el.find('.ai-chat-message-parent-name').remove()
      @$el.find('.treema-row').append $("<span class='ai-chat-message-parent-name'></span>").text(htmlText)
      


module.exports.AIDocumentLinkNode = AIDocumentLinkNode = class AIDocumentLinkNode extends TreemaNode.nodeMap.string
  buildValueForDisplay: (valEl, data) ->
    super valEl, data
    return unless data

    @$el.find('.ai-document-link').remove()
    @$el.find('.treema-row').prepend $("<span class='ai-document-link'><a href='/editor/ai-document/#{data}' title='Edit' target='_blank'>(e)</a>&nbsp;</span>")

module.exports.StateNode = StateNode = class SateNode extends TreemaNode.nodeMap.string
  buildValueForDisplay: (valEl, data) ->
    super valEl, data
    return unless data
    return console.error "Couldn't find state #{@data}" unless state = utils.usStateCodes.getStateNameByStateCode @data

    stateElement = -> $("<span> - <i>#{state}</i></span>")
    valEl.find('.treema-shortened').append(stateElement())

module.exports.conceptNodes = (concepts) -> 
  class ConceptNode extends TreemaNode.nodeMap.string
    buildValueForDisplay: (valEl, data) ->
      super valEl, data
      return unless data
      conceptList = concepts.map (i) -> i.toJSON()
      return console.error "Couldn't find concept #{@data}" unless concept = _.find conceptList, key: @data
      description = "#{concept.name} -- #{concept.description}"
      description = description + " (Deprecated)" if concept.deprecated
      description = "AUTO | " + description if concept.automatic
      @$el.find('.treema-row').css('float', 'left')
      @$el.addClass('concept-automatic') if concept.automatic
      @$el.addClass('concept-deprecated') if concept.deprecated
      @$el.find('.treema-description').remove()
      @$el.append($("<span class='treema-description'>#{description}</span>").show())

    limitChoices: (options) ->
      if @parent.keyForParent is 'concepts' and (not this.parent.parent)
        options = (o for o in options when _.find(concepts, (c) -> c.get('key') is o and not c.get('automatic') and not c.get('deprecated')))  # Allow manual, not automatic
      else
        options = (o for o in options when _.find(concepts, (c) -> c.get('key') is o and not c.get('deprecated')))  # Allow both
      super options

    onClick: (e) ->
      return if this.parent.keyForParent is 'concepts' and (not this.parent.parent) and @$el.hasClass('concept-automatic')  # Don't allow editing of automatic concepts
      super e

  class ConceptsListNode extends TreemaNode.nodeMap.array
    sort: true

    sortFunction: (a, b) ->
      aAutomatic = _.find concepts, (c) -> c.get('key') is a and c.get('automatic')
      bAutomatic = _.find concepts, (c) -> c.get('key') is b and c.get('automatic')
      return 1 if bAutomatic and not aAutomatic  # Auto before manual
      return -1 if aAutomatic and not bAutomatic  # Auto before manual
      return 0 if not aAutomatic and not bAutomatic  # No ordering within manual
      super a, b  # Alpha within auto
  return 
    ConceptsListNode: ConceptsListNode
    ConceptNode: ConceptNode
