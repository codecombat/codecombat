require('app/styles/account/account-prepaid-view.sass')
RootView = require 'views/core/RootView'
template = require 'templates/account/prepaid-view'
{getPrepaidCodeAmount} = require '../../core/utils'
SubscribeModal = require 'views/core/SubscribeModal'
CocoCollection = require 'collections/CocoCollection'
Prepaid = require '../../models/Prepaid'
utils = require 'core/utils'
Products = require 'collections/Products'


module.exports = class PrepaidView extends RootView
  id: 'prepaid-view'
  template: template
  className: 'container-fluid'

  events:
    'click #lookup-code-btn': 'onClickLookupCodeButton'
    'click #redeem-code-btn': 'onClickRedeemCodeButton'
    'click .start-subscription-button': 'onClickStartSubscription'

  initialize: ->
    super()

    # HACK: Make this one specific page responsive on mobile.
    $('head').append('<meta name="viewport" content="width=device-width; initial-scale=1.0; maximum-scale=1.0; user-scalable=0;">');

    @codes = new CocoCollection([], { url: '/db/user/'+me.id+'/prepaid_codes', model: Prepaid })
    @codes.on 'sync', (code) => @render?()
    @supermodel.loadCollection(@codes, {cache: false})

    @ppc = utils.getQueryVariable('_ppc') ? ''
    unless _.isEmpty(@ppc)
      @ppcQuery = true
      @loadPrepaid(@dashedPPC())

  getMeta: ->
    title: $.i18n.t 'account.prepaids_title'

  afterRender: ->
    super()
    @$el.find("span[title]").tooltip()

  statusMessage: (message, type='alert') ->
    noty text: message, layout: 'topCenter', type: type, killer: false, timeout: 5000, dismissQueue: true, maxVisible: 3

  dashedPPC: =>
    console.log('dashedppc', @ppc.length)
    if @ppc.length is 12
      return "#{@ppc.slice(0,4)}-#{@ppc.slice(4,8)}-#{@ppc.slice(8)}"
    @ppc

  onClickStartSubscription: =>
    @openModalView new SubscribeModal()

  confirmRedeem: =>

    options =
      url: '/db/subscription/-/subscribe_prepaid'
      method: 'POST'
      data: { ppc: @dashedPPC() }

    options.error = (model, res, options, foo) =>
      # console.error 'FAILED redeeming prepaid code'
      msg = model.responseText ? ''
      @statusMessage "Error: Could not redeem prepaid code. #{msg}", "error"

    options.success = (model, res, options) =>
      # console.log 'SUCCESS redeeming prepaid code'
      @statusMessage "Prepaid Code Redeemed!", "success"
      @supermodel.loadCollection(@codes, 'prepaid', {cache: false})
      @codes.fetch()
      me.fetch cache: false

    @supermodel.addRequestResource('subscribe_prepaid', options, 0).load()


  loadPrepaid: (ppc) ->
    return unless ppc
    options =
      cache: false
      method: 'GET'
      url: "/db/prepaid/-/code/#{ppc}"

    options.success = (model, res, options) =>
      @ppcInfo = []
      if model.get('type') is 'terminal_subscription'
        months = model.get('properties')?.months ? 0
        maxRedeemers = model.get('maxRedeemers') ? 0
        redeemers = model.get('redeemers') ? []
        if ppc.length == 14
          unlocksLeft = 1
        else
          unlocksLeft = maxRedeemers - redeemers.length
        @ppcInfo.push $.t('account_prepaid.prepaid_add_months', {months})
        @ppcInfo.push $.t('account_prepaid.can_use_times', {unlocksLeft})
        # TODO: user needs to know they can't apply it more than once to their account
      else
        @ppcInfo.push "Type: #{model.get('type')}"
      @render?()
    options.error = (model, res, options) =>
      console.log('res:', res, res.status, res.body)
      if res.status is 404
        if res.responseText is 'Activation code has been used'
          @ppcInfo.push "The Activation code has been used."
          @render?()
          return
      @statusMessage "Unable to retrieve code.", "error"

    @prepaid = new Prepaid()
    @prepaid.fetch(options)

  onClickLookupCodeButton: (e) ->
    @ppc = $('.input-ppc').val()
    unless @ppc
      @statusMessage "You must enter a code.", "error"
      return
    @ppcInfo = []
    @render?()
    @loadPrepaid(@dashedPPC())

  onClickRedeemCodeButton: (e) ->
    @ppc = $('.input-ppc').val()
    options =
      url: '/db/subscription/-/subscribe_prepaid'
      method: 'POST'
      data: { ppc: @dashedPPC()}
    options.error = (model, res, options, foo) =>
      msg = model.responseText ? ''
      @statusMessage "Error: Could not redeem prepaid code. #{msg}", "error"
    options.success = (model, res, options) =>
      @statusMessage "Prepaid applied to your account!", "success"
      @codes.fetch cache: false
      me.fetch cache: false
      @loadPrepaid(@dashedPPC())
    @supermodel.addRequestResource('subscribe_prepaid', options, 0).load()
