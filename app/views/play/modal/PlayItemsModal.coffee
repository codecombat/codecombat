require('app/styles/play/modal/play-items-modal.sass')
ModalView = require 'views/core/ModalView'
template = require 'templates/play/modal/play-items-modal'
buyGemsPromptTemplate = require 'templates/play/modal/buy-gems-prompt'
earnGemsPromptTemplate = require 'templates/play/modal/earn-gems-prompt'
subscribeForGemsPrompt = require 'templates/play/modal/subscribe-for-gems-prompt'
ItemDetailsView = require './ItemDetailsView'
BuyGemsModal = require 'views/play/modal/BuyGemsModal'
CreateAccountModal = require 'views/core/CreateAccountModal'
SubscribeModal = require 'views/core/SubscribeModal'

CocoCollection = require 'collections/CocoCollection'
ThangType = require 'models/ThangType'
LevelComponent = require 'models/LevelComponent'
Level = require 'models/Level'
Purchase = require 'models/Purchase'

utils = require 'core/utils'

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
    'click .subscribe-button': 'onSubscribeButtonClicked'
    'click .start-subscription-button': 'onSubscribeButtonClicked'
    'click .buy-gems-prompt-button': 'onBuyGemsPromptButtonClicked'
    'click #close-modal': 'hide'
    'click': 'onClickedSomewhere'
    'update .tab-pane .nano': 'showVisibleItemImages'
    'click #hero-type-select label': 'onClickHeroTypeSelect'

  constructor: (options) ->
    @showVisibleItemImages = _.throttle(_.bind(@showVisibleItemImages, @), 200)
    super options
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
      'description'
      'i18n'
      'heroClass'
      'subscriber'
    ]

    itemFetcher = new CocoCollection([], { url: '/db/thang.type?view=items', project: project, model: ThangType })
    itemFetcher.skip = 0
    itemFetcher.fetch({data: {skip: 0, limit: PAGE_SIZE}})
    @listenTo itemFetcher, 'sync', @onItemsFetched
    @stopListening @supermodel, 'loaded-all'
    @supermodel.loadCollection(itemFetcher, 'items')
    @idToItem = {}
    @trackTimeVisible()

  onItemsFetched: (itemFetcher) ->
    gemsOwned = me.gems()
    needMore = itemFetcher.models.length is PAGE_SIZE
    for model in itemFetcher.models
      model.owned = me.ownsItem model.get('original')
      continue unless (cost = model.get('gems')) or model.owned
      category = slotToCategory[model.getAllowedSlots()[0]] or 'misc'
      @itemCategoryCollections[category] ?= new Backbone.Collection()
      collection = @itemCategoryCollections[category]
      collection.comparator = (m) -> m.get('tier') ? m.get('gems')
      collection.add(model)
      model.name = utils.i18n model.attributes, 'name'
      model.affordable = cost <= gemsOwned
      model.silhouetted = not model.owned and model.isSilhouettedItem()
      model.level = model.levelRequiredForItem() if model.get('tier')?
      model.unequippable = not _.intersection(me.getHeroClasses(), model.getAllowedHeroClasses()).length
      model.comingSoon = not model.getFrontFacingStats().props.length and not _.size(model.getFrontFacingStats().stats) and not model.owned  # Temp: while there are placeholder items
      @idToItem[model.id] = model

    if itemFetcher.skip isnt 0
      # Make sure we render the newly fetched items, except the first time (when it happens automatically).
      @render()

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
    @playSound 'game-menu-open'
    @$el.find('.nano:visible').nanoScroller({alwaysVisible: true})
    @itemDetailsView = new ItemDetailsView()
    @insertSubView(@itemDetailsView)
    @$el.find("a[href='#item-category-armor']").click()  # Start on armor tab, if it's there.
    earnedLevels = me.get('earned')?.levels or []
    if Level.levels['defense-of-plainswood'] not in earnedLevels
      @$el.find('#misc-tab').hide()
      @$el.find('#hero-type-select #warrior').click()  # Start on warrior tab, if low level.
    @showVisibleItemImages()

  onHidden: ->
    super()
    @playSound 'game-menu-close'


  #- Click events

  onItemClicked: (e) ->
    return if $(e.target).closest('.unlock-button').length
    return if @destroyed
    @playSound 'menu-button-click'
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
    @updateViewVisibleTimer()

  currentVisiblePremiumFeature: ->
    item = @itemDetailsView?.item
    if 'pet' in (item?.getAllowedSlots() or []) or item?.get('heroClass') in ['Ranger', 'Wizard']
      return {
        viewName: @.id
        featureName: 'view-item'
        premiumThang:
          _id: item.id
          slug: item.get('slug')
          heroClass: item.get('heroClass')
          slots: item.getAllowedSlots()
      }
    else if @$el.find('.tab-content').hasClass('filter-wizard')
      return { viewName: @.id, featureName: 'filter-wizard' }
    else if @$el.find('.tab-content').hasClass('filter-ranger')
      return { viewName: @.id, featureName: 'filter-ranger' }
    else
      return null

  onTabClicked: (e) ->
    @playSound 'game-menu-tab-switch'
    nano = $($(e.target).attr('href')).find('.nano')
    nano.nanoScroller({alwaysVisible: true})
    @paneNanoContent = nano.find('.nano-content')
    @showVisibleItemImages()

  showVisibleItemImages: ->
    # dynamically load visible items when the user scrolls enough to see them
    return console.error "Couldn't update scroll, since paneNanoContent wasn't initialized." unless @paneNanoContent
    items = @paneNanoContent.find('.item:not(.loaded)')
    threshold = @paneNanoContent.height() + 100
    for itemEl in items
      itemEl = $(itemEl)
      if itemEl.position().top < threshold
        $(itemEl).addClass('loaded')
        item = @idToItem[itemEl.data('item-id')]
        itemEl.find('.item-silhouette, .item-img').attr('src', item.getPortraitURL())

  onClickHeroTypeSelect: (e) ->
    value = $(e.target).closest('label').attr('id')
    tabContent = @$el.find('.tab-content')
    tabContent.removeClass('filter-wizard filter-ranger filter-warrior')
    tabContent.addClass("filter-#{value}") if value isnt 'all'
    @updateViewVisibleTimer()

  onUnlockButtonClicked: (e) ->
    e.stopPropagation()
    button = $(e.target).closest('button')
    item = @idToItem[button.data('item-id')]
    gemsOwned = me.gems()
    cost = item.get('gems') ? 0
    affordable = cost <= gemsOwned
    if not affordable
      @playSound 'menu-button-click'
      @askToBuyGemsOrSubscribe button unless me.freeOnly() or application.getHocCampaign()
    else if button.hasClass('confirm')
      @playSound 'menu-button-unlock-end'
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
      console.log('render selectors', ".item[data-item-id='#{item.id}']", "#gems-count")
      @itemDetailsView.render()
      @showVisibleItemImages()

      Backbone.Mediator.publish 'store:item-purchased', item: item, itemSlug: item.get('slug')
    else
      @playSound 'menu-button-unlock-start'
      button.addClass('confirm').text($.i18n.t('play.confirm'))
      @$el.one 'click', (e) ->
        button.removeClass('confirm').text($.i18n.t('play.unlock')) if e.target isnt button[0]

  onSubscribeButtonClicked: (e) ->
    @openModalView new SubscribeModal()

  askToSignUp: ->
    createAccountModal = new CreateAccountModal supermodel: @supermodel
    return @openModalView createAccountModal

  askToBuyGemsOrSubscribe: (unlockButton) ->
    @$el.find('.unlock-button').popover 'destroy'
    if me.canBuyGems()
      popoverTemplate = buyGemsPromptTemplate {}
    else
      if not me.hasSubscription() # user does not have subscription ask him to subscribe to get more gems, china infra does not have 'buy gems' option
        popoverTemplate = subscribeForGemsPrompt {}
      else # user has subscription and yet not enough gems, just ask him to keep playing for more gems
        popoverTemplate = earnGemsPromptTemplate {}
   
    unlockButton.popover(
      animation: true
      trigger: 'manual'
      placement: 'top'
      content: ' '  # template has it
      container: @$el
      template: popoverTemplate
    ).popover 'show'
    popover = unlockButton.data('bs.popover')
    popover?.$tip?.i18n()
    @applyRTLIfNeeded()

  onBuyGemsPromptButtonClicked: (e) ->
    @playSound 'menu-button-click'
    return @askToSignUp() if me.get('anonymous')
    @openModalView new BuyGemsModal()

  onClickedSomewhere: (e) ->
    return if @destroyed
    @$el.find('.unlock-button').popover 'destroy'

  destroy: ->
    @$el.find('.unlock-button').popover 'destroy'
    super()
