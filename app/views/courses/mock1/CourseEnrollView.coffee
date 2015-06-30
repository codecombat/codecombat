app = require 'core/application'
RootView = require 'views/core/RootView'
template = require 'templates/courses/mock1/course-enroll'

module.exports = class CourseEnrollView extends RootView
  id: 'course-enroll-view'
  template: template

  events:
    'click .btn-buy': 'onClickBuy'
    'change .course-select': 'onChangeCourse'
    'change input:radio': 'onQuantityChange'

  constructor: (options, @courseID) ->
    super options
    @initData()

  getRenderData: ->
    context = super()
    context.courses = @courses ? {}
    context.courseID = @courseID
    context.price = @price ? 0
    context.quantity = @quantity
    context.selectedCourseTitle = @selectedCourseTitle
    context

  afterRender: ->
    super()
    @$el.find('.course-select').val(@selectedCourseTitle)

  initData: ->
    mockData = require 'views/courses/mock1/CoursesMockData'
    @courses = mockData.courses
    @selectedCourseTitle = @courses[@courseID]?.title
    @quantity = 20
    @updatePrice()

  onClickBuy: (e) ->
    if @selectedCourseTitle is 'All Courses'
      app.router.navigate "/courses/mock1/0"
    else
      for course, i in @courses when course.title is @selectedCourseTitle
        app.router.navigate "/courses/mock1/#{i}"
        break
    window.location.reload()

  onChangeCourse: (e) ->
    @selectedCourseTitle = $(e.target).val()
    @updatePrice()
    @render?()

  onQuantityChange: (e) ->
    @quantity = $(e.target).data('quantity')
    @updatePrice()
    @$el.find('.btn-buy').text("Buy #{@selectedCourseTitle} for $#{@price}")

  updatePrice: ->
    if @selectedCourseTitle is 'All Courses'
      @price = switch
        when @quantity is 20 then 499
        when @quantity is 50 then 999
        when @quantity is 100 then 1499
        else 2999
    else
      @price = switch
        when @quantity is 20 then 99
        when @quantity is 50 then 199
        when @quantity is 100 then 349
        else 799
