app = require 'core/application'
CreateAccountModal = require 'views/core/CreateAccountModal'
Classroom = require 'models/Classroom'
Classrooms = require 'collections/Classrooms'
CocoCollection = require 'collections/CocoCollection'
Course = require 'models/Course'
Prepaids = require 'collections/Prepaids'
RootView = require 'views/core/RootView'
stripeHandler = require 'core/services/stripe'
template = require 'templates/courses/enrollments-view'
User = require 'models/User'
Users = require 'collections/Users'
utils = require 'core/utils'
Products = require 'collections/Products'

module.exports = class EnrollmentsView extends RootView
  id: 'enrollments-view'
  template: template
  numberOfStudents: 15
  pricePerStudent: 0

  initialize: (options) ->
    @ownedClassrooms = new Classrooms()
    @ownedClassrooms.fetchMine({data: {project: '_id'}})
    @supermodel.trackCollection(@ownedClassrooms)
    @listenTo stripeHandler, 'received-token', @onStripeReceivedToken
    @fromClassroom = utils.getQueryVariable('from-classroom')
    @members = new Users()
    # @listenTo @members, 'sync add remove', @calculateEnrollmentStats
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
    'click .purchase-now': 'onClickPurchaseButton'
    # 'click .enroll-students': 'onClickEnrollStudents'

  onLoaded: ->
    @calculateEnrollmentStats()
    @pricePerStudent = @products.findWhere({name: 'course'}).get('amount')
    me.setRole 'teacher'
    super()

  getPriceString: -> '$' + (@getPrice()/100).toFixed(2)
  getPrice: -> @pricePerStudent * @numberOfStudents

  onceClassroomsSync: ->
    for classroom in @classrooms.models
      @supermodel.trackRequests @members.fetchForClassroom(classroom, {remove: false, removeDeleted: true})

  calculateEnrollmentStats: ->
    @removeDeletedStudents()
    @memberEnrolledMap = {}
    for user in @members.models
      @memberEnrolledMap[user.id] = user.get('coursePrepaidID')?
      
    @totalEnrolled = _.reduce @members.models, ((sum, user) ->
      sum + (if user.get('coursePrepaidID') then 1 else 0)
    ), 0
    
    @numberOfStudents = @totalNotEnrolled = _.reduce @members.models, ((sum, user) ->
      sum + (if not user.get('coursePrepaidID') then 1 else 0)
    ), 0
    
    @classroomEnrolledMap = _.reduce @classrooms.models, ((map, classroom) =>
      enrolled = _.reduce classroom.get('members'), ((sum, userID) =>
        sum + (if @members.get(userID).get('coursePrepaidID') then 1 else 0)
      ), 0
      map[classroom.id] = enrolled
      map
    ), {}
    
    @classroomNotEnrolledMap = _.reduce @classrooms.models, ((map, classroom) =>
      enrolled = _.reduce classroom.get('members'), ((sum, userID) =>
        sum + (if not @members.get(userID).get('coursePrepaidID') then 1 else 0)
      ), 0
      map[classroom.id] = enrolled
      map
    ), {}
    
    true
    
  removeDeletedStudents: (e) ->
    for classroom in @classrooms.models
      _.remove(classroom.get('members'), (memberID) =>
        not @members.get(memberID) or @members.get(memberID)?.get('deleted')
      )
    true

  onInputStudentsInput: ->
    input = @$('#students-input').val()
    if input isnt "" and (parseFloat(input) isnt parseInt(input) or _.isNaN parseInt(input))
      @$('#students-input').val(@numberOfStudents)
    else
      @numberOfStudents = Math.max(parseInt(@$('#students-input').val()) or 0, 0)
      @updatePrice()

  updatePrice: ->
    @renderSelectors '#price-form-group'

  numberOfStudentsIsValid: -> 0 < @numberOfStudents < 100000
  
  # onClickEnrollStudents: ->
  # TODO: Needs "All students" in modal dropdown

  onClickPurchaseButton: ->
    return @openModalView new CreateAccountModal() if me.isAnonymous()
    unless @numberOfStudentsIsValid()
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
      success: (prepaid) ->
        application.tracker?.trackEvent 'Finished course prepaid purchase', {price: @pricePerStudent, seats: @numberOfStudents}
        @state = 'purchased'
        @prepaids.add(prepaid)
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
