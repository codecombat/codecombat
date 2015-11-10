ModalView = require 'views/core/ModalView'
template = require 'templates/admin/administer-user-modal'
User = require 'models/User'
Prepaid = require 'models/Prepaid'

module.exports = class AdministerUserModal extends ModalView
  id: "administer-user-modal"
  template: template
  plain: true

  events:
    'click #save-changes': 'onSaveChanges'
    'click #add-seats-btn': 'onClickAddSeatsButton'

  constructor: (options, @userHandle) ->
    super(options)
    @user = @supermodel.loadModel(new User({_id:@userHandle}), 'user', {cache: false}).model
    options = {cache: false, url: '/stripe/coupons'}
    options.success = (@coupons) =>
    @couponsResource = @supermodel.addRequestResource('coupon', options)
    @couponsResource.load()

  getRenderData: ->
    c = super()
    stripe = @user.get('stripe') or {}
    c.free = stripe.free is true
    c.freeUntil = _.isString(stripe.free)
    c.freeUntilDate = if c.freeUntil then stripe.free else new Date().toISOString()[...10]
    c.coupon = stripe.couponID
    c.coupons = @coupons or []
    for coupon in c.coupons
      bits = [coupon.id]
      if coupon.percent_off
        bits.push "(#{coupon.percent_off}% off)"
      else if coupon.amount_off
        bits.push "($#{coupon.amount_off} off)"
      if coupon.duration
        bits.push "(duration: #{coupon.duration})"
      if coupon.redeem_by
        bits.push "(redeem by: #{moment(coupon.redeem_by).format('lll')}"
      coupon.format = bits.join(' ')
    c.none = not (c.free or c.freeUntil or c.coupon)
    c.user = @user
    c

  onSaveChanges: ->
    stripe = _.clone(@user.get('stripe') or {})
    delete stripe.free
    delete stripe.couponID

    selection = @$el.find('input[name="stripe-benefit"]:checked').val()
    dateVal = @$el.find('#free-until-date').val()
    couponVal = @$el.find('#coupon-select').val()
    switch selection
      when 'free' then stripe.free = true
      when 'free-until' then stripe.free = dateVal
      when 'coupon' then stripe.couponID = couponVal

    @user.set('stripe', stripe)
    options = {}
    options.success = => @hide()
    @user.patch(options)

  onClickAddSeatsButton: ->
    maxRedeemers = parseInt(@$('#seats-input').val())
    return unless maxRedeemers and maxRedeemers > 0
    prepaid = new Prepaid({
      maxRedeemers: maxRedeemers
      type: 'course'
      creator: @user.id
    })
    prepaid.save()
    @state = 'creating-prepaid'
    @renderSelectors('#prepaid-form')
    @listenTo prepaid, 'sync', ->
      @state = 'made-prepaid'
      @renderSelectors('#prepaid-form')
