app = require 'core/application'
AuthModal = require 'views/core/AuthModal'
CocoCollection = require 'collections/CocoCollection'
Course = require 'models/Course'
RootView = require 'views/core/RootView'
stripeHandler = require 'core/services/stripe'
template = require 'templates/courses/purchase-courses-view'
utils = require 'core/utils'

module.exports = class PurchaseCoursesView extends RootView
  id: 'purchase-courses-view'
  template: template
  numberOfStudents: 30
  pricePerStudent: 4
  
  initialize: (options) ->
    @listenTo stripeHandler, 'received-token', @onStripeReceivedToken
    super(options)
  
  events:
    'input #students-input': 'onInputStudentsInput'
    'click #purchase-btn': 'onClickPurchaseButton'

  getPriceString: -> '$' + (@getPrice()).toFixed(2)
  getPrice: -> @pricePerStudent * @numberOfStudents

  onInputStudentsInput: ->
    @numberOfStudents = parseInt(@$('#students-input').val()) or 0
    @updatePrice()

  updatePrice: ->
    @renderSelectors '#price-form-group'

  onClickPurchaseButton: ->
    return @openModalView new AuthModal() if me.isAnonymous()
    if @numberOfStudents < 1 or not _.isFinite(@numberOfStudents)
      alert("Please enter the maximum number of students needed for your class.")
      return

    @state = undefined
    @stateMessage = undefined
    @render()

    # Show Stripe handler
    application.tracker?.trackEvent 'Started course prepaid purchase', {
      price: @pricePerStudent, students: @pricePerStudent}
    stripeHandler.open
      amount: @price
      description: "Full course access for #{@numberOfStudents} students"
      bitcoin: true
      alipay: if me.get('country') is 'china' or (me.get('preferredLanguage') or 'en-US')[...2] is 'zh' then true else 'auto'

  onStripeReceivedToken: (e) ->
    @state = 'purchasing'
    @render?()
    console.log 'e', e
    
    data =
      maxRedeemers: @numberOfStudents
      type: 'course'
      stripe:
        token: e.token.id
        timestamp: new Date().getTime()
      
    $.ajax({
      url: '/db/prepaid/-/purchase',
      data: data,
      method: 'POST',
      context: @
      success: ->
        application.tracker?.trackEvent 'Finished course prepaid purchase', {price: @pricePerStudent, seats: @numberOfStudents}
        @state = 'purchased'
        @render?()
        
      error: (jqxhr, textStatus, errorThrown) ->
        application.tracker?.trackEvent 'Failed course prepaid purchase', status: textStatus
        if jqxhr.status is 402
          @state = 'error'
          @stateMessage = arguments[2]
        else
          @state = 'error'
          @stateMessage = "#{jqxhr.status}: #{jqxhr.responseText}"
        @render?()
    })

