app = require 'core/application'
RootView = require 'views/core/RootView'
template = require 'templates/courses/mock1/course-enroll'

module.exports = class CourseEnrollView extends RootView
  id: 'course-enroll-view'
  template: template

  events:
    'click .btn-buy': 'onClickBuy'
    'change .course-select': 'onChangeCourse'
    'change .input-quantity': 'onQuantityChange'

  constructor: (options, @courseID=0) ->
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
    @quantity = $(e.target).val() ? 20
    @updatePrice()
    @render?()

  updatePrice: ->
    if @selectedCourseTitle is 'All Courses'
      @price = (@courses.length - 1) * @quantity * 2
    else if @selectedCourseTitle is 'Introduction to Computer Science'
      @price = 0
    else
      @price = @quantity * 4
