app = require 'core/application'
AuthModal = require 'views/core/AuthModal'
Classroom = require 'models/Classroom'
CocoCollection = require 'collections/CocoCollection'
Course = require 'models/Course'
Prepaids = require 'collections/Prepaids'
RootView = require 'views/core/RootView'
stripeHandler = require 'core/services/stripe'
template = require 'templates/courses/purchase-courses-view'
User = require 'models/User'
utils = require 'core/utils'
Products = require 'collections/Products'

module.exports = class PurchaseCoursesView extends RootView
  id: 'purchase-courses-view'
  template: template
  numberOfStudents: 30
  pricePerStudent: 0

  initialize: (options) ->
    @listenTo stripeHandler, 'received-token', @onStripeReceivedToken
    @fromClassroom = utils.getQueryVariable('from-classroom')
    @members = new CocoCollection([], { model: User })
    @listenTo @members, 'sync', @membersSync
    @classrooms = new CocoCollection([], { url: "/db/classroom", model: Classroom })
    @classrooms.comparator = '_id'
    @listenToOnce @classrooms, 'sync', @onceClassroomsSync
    @supermodel.loadCollection(@classrooms, 'classrooms', {data: {ownerID: me.id}})
    @prepaids = new Prepaids()
    @prepaids.comparator = '_id'
    @prepaids.fetchByCreator(me.id)
    @supermodel.loadCollection(@prepaids, 'prepaids')
    @products = new Products()
    @supermodel.loadCollection(@products, 'products')
    super(options)

  events:
    'input #students-input': 'onInputStudentsInput'
    'click #purchase-btn': 'onClickPurchaseButton'
    
  onLoaded: ->
    @pricePerStudent = @products.findWhere({name: 'course'}).get('amount')
    super()

  getPriceString: -> '$' + (@getPrice()/100).toFixed(2)
  getPrice: -> @pricePerStudent * @numberOfStudents

  onceClassroomsSync: ->
    for classroom in @classrooms.models
      @members.fetch({
        remove: false
        url: "/db/classroom/#{classroom.id}/members"
      })

  membersSync: ->
    @memberEnrolledMap = {}
    for user in @members.models
      @memberEnrolledMap[user.id] = user.get('coursePrepaidID')?
    @classroomNotEnrolledMap = {}
    @totalNotEnrolled = 0
    for classroom in @classrooms.models
      @classroomNotEnrolledMap[classroom.id] = 0
      for memberID in classroom.get('members')
        @classroomNotEnrolledMap[classroom.id]++ unless @memberEnrolledMap[memberID]
      @totalNotEnrolled += @classroomNotEnrolledMap[classroom.id]
    @numberOfStudents = @totalNotEnrolled
    @render?()

  onInputStudentsInput: ->
    @numberOfStudents = Math.max(parseInt(@$('#students-input').val()) or 0, 0)
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
      price: @pricePerStudent, students: @numberOfStudents}
    stripeHandler.open
      amount: @numberOfStudents * @pricePerStudent
      description: "Full course access for #{@numberOfStudents} students"
      bitcoin: true
      alipay: if me.get('country') is 'china' or (me.get('preferredLanguage') or 'en-US')[...2] is 'zh' then true else 'auto'

  onStripeReceivedToken: (e) ->
    @state = 'purchasing'
    @render?()

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
