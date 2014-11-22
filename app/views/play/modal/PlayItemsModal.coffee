ModalView = require 'views/kinds/ModalView'
template = require 'templates/play/modal/play-items-modal'
ItemDetailsView = require './ItemDetailsView'

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
      'tier'
      'i18n'
      'heroClass'
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
      model.owned = me.ownsItem model.get('original')
      continue unless (cost = model.get('gems')) or model.owned
      category = slotToCategory[model.getAllowedSlots()[0]] or 'misc'
      @itemCategoryCollections[category] ?= new Backbone.Collection()
      collection = @itemCategoryCollections[category]
      collection.comparator = (m) -> m.get('gems') ? m.get('tier')
      collection.add(model)
      model.name = utils.i18n model.attributes, 'name'
      model.affordable = cost <= gemsOwned
      model.silhouetted = not model.owned and model.isSilhouettedItem()
      model.level = model.levelRequiredForItem() if model.get('tier')?
      model.unequippable = not ('Warrior' in model.getAllowedHeroClasses())  # Temp: while there are no wizards/rangers
      model.comingSoon = not model.getFrontFacingStats().props.length and not _.size(model.getFrontFacingStats().stats) and not model.owned  # Temp: while there are placeholder items
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
    @$el.find('.nano:visible').nanoScroller({alwaysVisible: true})
    @itemDetailsView = new ItemDetailsView()
    @insertSubView(@itemDetailsView)
    @$el.find("a[href='#item-category-armor']").click()  # Start on armor tab, if it's there.

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
      if item.silhouetted and not item.owned
        item = null
      else
        itemEl.addClass('selected') unless wasSelected
    @itemDetailsView.setItem(item)

  onTabClicked: (e) ->
    $($(e.target).attr('href')).find('.nano').nanoScroller({alwaysVisible: true})

  onUnlockButtonClicked: (e) ->
    button = $(e.target).closest('button')
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

      Backbone.Mediator.publish 'store:item-purchased', item: item, itemSlug: item.get('slug')
    else
      button.addClass('confirm').text($.i18n.t('play.confirm'))
      @$el.one 'click', (e) ->
        button.removeClass('confirm').text($.i18n.t('play.unlock')) if e.target isnt button[0]
