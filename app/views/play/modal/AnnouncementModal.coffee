require('app/styles/play/modal/announcement-modal.sass')
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
    'mouseover .has-tooltip': 'displayTooltip'
    'mousemove .has-tooltip': 'displayTooltip'
    'mouseout .has-tooltip': 'hideTooltip'

    'click .ability-icon': 'onClickAbilityIcon'
    'click .ritic-block': 'onClickRiticBlock'

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
        $(randomItem).addClass('wiggle')
        setTimeout(() ->
          $(randomItem).removeClass('wiggle')
        , 1000)
    , 1000)

  onClickAbilityIcon: (e) ->
    $(".gif-video").hide()
    $("#" + $(e.currentTarget).data("gif") + "-gif").show()

  onClickRiticBlock: (e) ->
    elem = $(e.currentTarget)
    spawnSomeShards = (num) ->
      for i in [0...num]
        img = $("<img>").attr("src", "/images/pages/play/modal/announcement/ritic/shard#{Math.floor(1 + Math.random() * 6)}.png").addClass("shard")
        left = Math.floor(25 + 50 * Math.random())
        top =  Math.floor(75 - 30 * Math.random())
        img.css({left: left + "%", top: top + "%"})
        img.css("transform", "rotate(0deg)")
        $("#ice-chamber").append(img)
        randNum = Math.random() * Math.PI * 2
        img.animate({
          opacity: 0,
          left: (left + Math.cos(randNum) * 100) + "%",
          top: (top + Math.sin(randNum) * 100) + "%"},
          740 + Math.random() * 2000, () ->
            $(this).remove()
        )
        img.css("transform", "rotate(#{-360 + Math.floor(Math.random() * 360 * 2)}deg)")
    if elem.hasClass('ritic-block-1')
      elem.removeClass('ritic-block-1')
      elem.addClass('ritic-block-2')
      $("#clear-block").hide()
      $("#chipped-block").show()
      spawnSomeShards(2)
    else if elem.hasClass('ritic-block-2')
      elem.removeClass('ritic-block-2')
      $("#chipped-block").hide()
      $("#shattered-block").show()
      $("#shattered-block").css("opacity", 1)
      elem.addClass('ritic-block-3')
      spawnSomeShards(10)
    else if elem.hasClass('ritic-block-3')
      elem.removeClass('ritic-block-3')
      $("#shattered-block").css("opacity", 0)
      $("#ritic-image").addClass("breathing")
      $("#ritic-image").css("cursor", "default")
      $("#ritic-image").data("name", "announcement.ritic")
      $("#ritic-image").data("description", "announcement.ritic_description")
      @hideTooltip()
      $(".highlight").each((i, elem) ->
        $(this).show()
        $(this).css("animation","highlight#{if i % 2 then '-reverse' else ''}-anim #{5 + i}s linear infinite")
      )
      spawnSomeShards(25)

  displayTooltip: (e) ->
    if $(e.currentTarget).data("name")?
      w = $(".paper-area").offset()
      x = $(".paper-area").position()
      $("#item-tooltip").show().css("left", ((e.clientX - w.left) + 96) + "px")
      $("#item-tooltip").show().css("top", ((e.clientY - w.top)) + "px")
      if $(e.currentTarget).data('coming-soon')?
        $("#item-tooltip #coming-soon").show()
      else
        $("#item-tooltip #coming-soon").hide()
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
