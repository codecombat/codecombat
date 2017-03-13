ModalView = require 'views/core/ModalView'
utils = require 'core/utils'
CreateAccountModal = require 'views/core/CreateAccountModal'
SubscribeModal = require 'views/core/SubscribeModal'
Products = require 'collections/Products'

module.exports = class AnnouncementModal extends ModalView
  id: 'announcement-modal'
  plain: true
  closesOnClickOutside: true
  modalPath: 'views/play/modal/AnnouncementModal'

  announcementId = null

  events:
    'click #close-modal': 'hide'
    'click .purchase-button': 'onClickPurchaseButton'
    'click .close-button': 'hide'

  constructor: (options={}) ->
    options.announcementId ?= 1
    announcementId = options.announcementId
    @template = require "templates/play/modal/announcements/#{options.announcementId}"
    super(options)
    @trackTimeVisible({ trackViewLifecycle: true })

  afterRender: ->
    super()
    @playSound 'game-menu-open'

  afterInsert: ->
    super()
    @timerIntervalID = setInterval(() =>
      return if @isHover
      elems = $(".pet-image").toArray()
      randomNum = Math.floor(Math.random() * elems.length)
      randomItem = elems[randomNum]
      if randomItem
        $(randomItem).addClass('shimmy')
        setTimeout(() ->
          $(randomItem).removeClass('shimmy')
        , 1000)
    , 1000)
    $(".pet-image").on('mouseover', (e) =>
      @displayTooltip(e)
    )
    $(".pet-image").on('mousemove', (e) =>
      @displayTooltip(e)
    )
    $(".pet-image").on('mouseout', (e) =>
      @hideTooltip()
    )

  displayTooltip: (e) ->
    w = $(".paper-area").offset()
    x = $(".paper-area").position()
    $("#item-tooltip").show().css("left", ((e.clientX - w.left) + 96) + "px")
    $("#item-tooltip").show().css("top", ((e.clientY - w.top)) + "px")
    $("#item-tooltip #pet-name").text($.i18n.t($(e.currentTarget).data("name")))
    $("#item-tooltip #pet-description").text($.i18n.t($(e.currentTarget).data("description")))
    @isHover = true

  hideTooltip: () ->
    $("#item-tooltip").hide()
    @isHover = false

  onClickPurchaseButton: (e) =>
    @playSound 'menu-button-click'
    @openModalView new SubscribeModal()
    window.tracker?.trackEvent 'Show subscription modal', category: 'Subscription', label: "announcement modal id: #{announcementId}"

  onHidden: ->
    super()
    @playSound 'game-menu-close'

  destroy: ->
    clearInterval(@timerIntervalID)
    super()
