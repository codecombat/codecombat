app = require 'core/application'
AuthModal = require 'views/core/AuthModal'
CocoCollection = require 'collections/CocoCollection'
Course = require 'models/Course'
RootView = require 'views/core/RootView'
stripeHandler = require 'core/services/stripe'
template = require 'templates/courses/course-enroll'
utils = require 'core/utils'

module.exports = class CourseEnrollView extends RootView
  id: 'course-enroll-view'
  template: template

  events:
    'click .btn-buy': 'onClickBuy'
    'change .class-name': 'onNameChange'
    'change .course-select': 'onChangeCourse'
    'change .input-seats': 'onSeatsChange'
    'change #programming-language-select': 'onChangeProgrammingLanguageSelect'

  subscriptions:
    'stripe:received-token': 'onStripeReceivedToken'

  constructor: (options, @courseID) ->
    super options
    @courseID ?= options.courseID
    @seats = 20
    @selectedLanguage = 'python'

    @courses = new CocoCollection([], { url: "/db/course", model: Course})
    @listenTo @courses, 'sync', @onCoursesLoaded
    @supermodel.loadCollection(@courses, 'courses')

  afterRender: ->
    super()
    if @selectedCourse
      @$el.find('.course-select').val(@selectedCourse.id)
    else
      @$el.find('.course-select').val('All Courses')

  onCoursesLoaded: ->
    if @courseID
      @selectedCourse = _.find @courses.models, (a) => a.id is @courseID
    else if @courses.models.length > 0
      @selectedCourse = @courses.models[0]
    @renderNewPrice()

  onClickBuy: (e) ->
    return @openModalView new AuthModal() if me.isAnonymous()

    if @price is 0
      @seats = 9999
      @state = 'creating'
      @createClass()
      return

    if @seats < 1 or not _.isFinite(@seats)
      alert("Please enter the maximum number of students needed for your class.")
      return

    @state = undefined
    @stateMessage = undefined
    @render()

    # Show Stripe handler
    courseTitle = @selectedCourse?.get('name') ? 'All Courses'
    application.tracker?.trackEvent 'Started course purchase', {course: courseTitle, price: @price, seats: @seats}
    stripeHandler.open
      amount: @price
      description: "#{courseTitle} for #{@seats} students"
      bitcoin: true
      alipay: if me.get('country') is 'china' or (me.get('preferredLanguage') or 'en-US')[...2] is 'zh' then true else 'auto'

  onStripeReceivedToken: (e) ->
    @state = 'purchasing'
    @render?()
    @createClass(e.token.id)

  onChangeCourse: (e) ->
    @selectedCourse = _.find @courses.models, (a) -> a.id is $(e.target).val()
    @renderNewPrice()
    
  onChangeProgrammingLanguageSelect: (e) ->
    @selectedLanguage = @$('#programming-language-select').val()

  onNameChange: (e) ->
    @className = $('.class-name').val()

  onSeatsChange: (e) ->
    @seats = $(e.target).val()
    @seats = 20 if @seats < 1 or not _.isFinite(@seats)
    @renderNewPrice()

  createClass: (token) ->
    data =
      name: @className
      seats: @seats
      stripe:
        token: token
        timestamp: new Date().getTime()
      aceConfig: { language: @selectedLanguage }
      
    data.courseID = @selectedCourse.id if @selectedCourse
    jqxhr = $.post('/db/course_instance/-/create', data)
    jqxhr.done (data, textStatus, jqXHR) =>
      application.tracker?.trackEvent 'Finished course purchase', {course: @selectedCourse?.get('name') ? 'All Courses', price: @price, seats: @seats}
      # TODO: handle fetch errors
      me.fetch(cache: false).always =>
        courseID = @selectedCourse?.id ? @courses.models[0]?.id
        route = "/courses/#{courseID}"
        viewArgs = [{}, courseID]
        if data?.length > 0
          courseInstanceID = data[0]._id
          route += "/#{courseInstanceID}"
          viewArgs[0].courseInstanceID = courseInstanceID
        Backbone.Mediator.publish 'router:navigate',
          route: route
          viewClass: 'views/courses/CourseDetailsView'
          viewArgs: viewArgs
    jqxhr.fail (xhr, textStatus, errorThrown) =>
      console.error 'Got an error purchasing a course:', textStatus, errorThrown
      application.tracker?.trackEvent 'Failed course purchase', status: textStatus
      if xhr.status is 402
        @state = 'declined'
        @stateMessage = arguments[2]
      else
        @state = 'unknown_error'
        @stateMessage = "#{xhr.status}: #{xhr.responseText}"
      @render?()

  renderNewPrice: ->
    if @selectedCourse
      coursePrices = [@selectedCourse.get('pricePerSeat')]
    else
      coursePrices = (c.get('pricePerSeat') for c in @courses.models)
    @price = utils.getCourseBundlePrice(coursePrices, @seats)
    @price = 0 if me.isAdmin()
    @render?()
