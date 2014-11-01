ModalView = require 'views/kinds/ModalView'
CocoView = require 'views/kinds/CocoView'

template = require 'templates/play/modal/play-items-modal'
itemDetailsTemplate = require 'templates/play/modal/item-details-view'

CocoCollection = require 'collections/CocoCollection'
ThangType = require 'models/ThangType'
LevelComponent = require 'models/LevelComponent'
Purchase = require 'models/Purchase'

utils = require 'lib/utils'

PAGE_SIZE = 200

slotToCategory = {
  'right-hand': 'primary'

  'left-hand': 'secondary'

  'head': 'armor'
  'torso': 'armor'
  'gloves': 'armor'
  'feet': 'armor'

  'eyes': 'accessories'
  'neck': 'accessories'
  'wrists': 'accessories'
  'left-ring': 'accessories'
  'right-ring': 'accessories'
  'waist': 'accessories'

  'pet': 'misc'
  'minion': 'misc'
  'flag': 'misc'
  'misc-0': 'misc'
  'misc-1': 'misc'

  'programming-book': 'books'
}

module.exports = class PlayItemsModal extends ModalView
  className: 'modal fade play-modal'
  template: template
  id: 'play-items-modal'

  events:
    'click .item': 'onItemClicked'
    'shown.bs.tab': 'onTabClicked'
    'click .unlock-button': 'onUnlockButtonClicked'
    'click #close-modal': 'hide'

  constructor: (options) ->
    super options
    me.set('spent', 0)
    @items = new Backbone.Collection()
    @itemCategoryCollections = {}
    
    project = [
      'name'
      'components.config'
      'components.original'
      'slug'
      'original'
      'rasterIcon'
      'gems'
      'i18n'
    ]
    
    itemFetcher = new CocoCollection([], { url: '/db/thang.type?view=items', project: project, model: ThangType })
    itemFetcher.skip = 0
    itemFetcher.fetch({data: {skip: 0, limit: PAGE_SIZE}})
    @listenTo itemFetcher, 'sync', @onItemsFetched
    @supermodel.loadCollection(itemFetcher, 'items')
    @idToItem = {}

  onItemsFetched: (itemFetcher) ->
    gemsOwned = me.gems()
    needMore = itemFetcher.models.length is PAGE_SIZE
    for model in itemFetcher.models
      continue unless cost = model.get('gems')
      category = slotToCategory[model.getAllowedSlots()[0]] or 'misc'
      @itemCategoryCollections[category] ?= new Backbone.Collection()
      collection = @itemCategoryCollections[category]
      collection.comparator = 'gems'
      collection.add(model)
      model.name = utils.i18n model.attributes, 'name'
      model.affordable = cost <= gemsOwned
      model.owned = me.ownsItem model.get('original')
      model.silhouetted = model.isSilhouettedItem()
      @idToItem[model.id] = model

    if needMore
      itemFetcher.skip += PAGE_SIZE
      itemFetcher.fetch({data: {skip: itemFetcher.skip, limit: PAGE_SIZE}})
      
  getRenderData: (context={}) ->
    context = super(context)
    context.itemCategoryCollections = @itemCategoryCollections
    context.itemCategories = _.keys @itemCategoryCollections
    context.itemCategoryNames = ($.i18n.t "items.#{category}" for category in context.itemCategories)
    context.gems = me.gems()
    context

  afterRender: ->
    super()
    return unless @supermodel.finished()
    Backbone.Mediator.publish 'audio-player:play-sound', trigger: 'game-menu-open', volume: 1
    @$el.find('.modal-dialog').css({width: "1230px", height: "660px", background: 'none'})
    @$el.find('.background-wrapper').css({'background', 'none'})
    @$el.find('.nano:visible').nanoScroller({alwaysVisible: true})
    @itemDetailsView = new ItemDetailsView()
    @insertSubView(@itemDetailsView)

  onHidden: ->
    super()
    Backbone.Mediator.publish 'audio-player:play-sound', trigger: 'game-menu-close', volume: 1

    
  #- Click events
    
  onItemClicked: (e) ->
    return if $(e.target).closest('.unlock-button').length
    itemEl = $(e.target).closest('.item')
    wasSelected = itemEl.hasClass('selected')
    @$el.find('.item.selected').removeClass('selected')
    if wasSelected
      item = null
    else
      item = @idToItem[itemEl.data('item-id')]
      if item.silhouetted
        item = null
      else
        itemEl.addClass('selected') unless wasSelected
    @itemDetailsView.setItem(item)
    
  onTabClicked: (e) ->
    $($(e.target).attr('href')).find('.nano').nanoScroller({alwaysVisible: true})

  onUnlockButtonClicked: (e) ->
    button = $(e.target)
    if button.hasClass('confirm')
      item = @idToItem[$(e.target).data('item-id')]
      purchase = Purchase.makeFor(item)
      purchase.save()
      
      #- set local changes to mimic what should happen on the server...
      purchased = me.get('purchased') ? {}
      purchased.items ?= []
      purchased.items.push(item.get('original'))
      item.owned = true
      me.set('purchased', purchased)
      me.set('spent', (me.get('spent') ? 0) + item.get('gems'))
      
      #- ...then rerender key bits
      @renderSelectors(".item[data-item-id='#{item.id}']", "#gems-count")
      @itemDetailsView.render()
    else
      button.addClass('confirm').text($.i18n.t('play.confirm'))
      @$el.one 'click', (e) ->
        button.removeClass('confirm').text($.i18n.t('play.unlock')) if e.target isnt button[0]
    
class ItemDetailsView extends CocoView
  id: "item-details-view"
  template: itemDetailsTemplate
  
  constructor: ->
    super(arguments...)
    @propDocs = {}
  
  setItem: (@item) -> 
    @render()
    
    if @item
      stats = @item.getFrontFacingStats()
      props = (p for p in stats.props when not @propDocs[p])
      return if props.length is 0
      
      docs = new CocoCollection([], { 
        url: '/db/level.component?view=prop-doc-lookup'
        model: LevelComponent
        project: [
          'propertyDocumentation.name'
          'propertyDocumentation.description'
          'propertyDocumentation.i18n'
        ]
      })

      docs.fetch({ data: {
        componentOriginals: [c.original for c in @item.get('components')].join(',')
        propertyNames: props.join(',')
      }})
      @listenToOnce docs, 'sync', @onDocsLoaded

  onDocsLoaded: (levelComponents) ->
    for component in levelComponents.models
      for propDoc in component.get('propertyDocumentation')
        @propDocs[propDoc.name] = propDoc
    @render()
  
  getRenderData: ->
    c = super()
    c.item = @item
    if @item
      stats = @item.getFrontFacingStats()
      c.stats = _.values(stats.stats)
      _.last(c.stats).isLast = true if c.stats.length
      c.props = []
      progLang = (me.get('aceConfig') ? {}).language or 'python'
      for prop in stats.props
        description = utils.i18n @propDocs[prop] ? {}, 'description'
        
        if _.isObject description
          description = description[progLang] or _.values(description)[0]
        if _.isString description
          description = description.replace(/#{spriteName}/g, 'hero')
          if fact = stats.stats.shieldDefenseFactor
            description = description.replace(/#{shieldDefensePercent}%/g, fact.display)
          description = $(marked(description)).html()
          
        c.props.push {
          name: prop
          description: description or '...'
        }
    c