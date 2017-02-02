RootView = require 'views/core/RootView'
OutcomeReportResult = require 'views/admin/OutcomeReportResult'
template = require 'templates/base-flat'
User = require 'models/User'
TrialRequest = require 'models/TrialRequest'
TrialRequests = require 'collections/TrialRequests'
Classrooms = require 'collections/Classrooms'
Courses = require 'collections/Courses'
CourseInstances = require 'collections/CourseInstances'
require('vendor/co')
require('vendor/vue')
require('vendor/vuex')

module.exports = class OutcomesReportView extends RootView
  id: 'skipped-contacts-view'
  template: template

  afterRender: ->
    @vueComponent?.$destroy()
    @vueComponent = new OutcomesReportComponent({
      data: {}
      el: @$el.find('#site-content-area')[0]
      store: @store
    })
    super(arguments...)

OutcomesReportComponent = Vue.extend
  template: require('templates/admin/outcomes-report-view')()
  data: ->
    accountManager: me.toJSON()
    teacherEmail: '580e517382bf11520af8a1f6' # TODO: Don't hardcode this. And add get-by-email endpoint.
    teacher: null
    teacherFullName: null
    accountManagerFullName: null
    schoolNameAndAddress: null
    trialRequest: null
    startDate: null
    classrooms: null
    courses: null
    isClassroomSelected: {}
    isCourseSelected: {}
    endDate: moment(new Date()).format('YYYY-MM-DD')
  computed:
    {}
  watch:
    teacher: (teacher) ->
      if teacher.firstName && teacher.lastName
        @teacherFullName = "#{teacher.firstName} #{teacher.lastName}"
      else
        @teacherFullName = teacher.email
    trialRequest: (trialRequest) ->
      @schoolNameAndAddress = trialRequest?.properties.school
      @startDate = moment(new Date(trialRequest.created)).format('YYYY-MM-DD')
    classrooms: (classrooms) ->
      for classroom in classrooms
        if _.isUndefined(@isClassroomSelected[classroom._id])
          Vue.set(@isClassroomSelected, classroom._id, true)
    courses: (courses) ->
      for course in courses
        if _.isUndefined(@isCourseSelected[course._id])
          Vue.set(@isCourseSelected, course._id, true)
  methods:
    submitEmail: (e) ->
      $.ajax
        type: 'POST',
        url: '/db/user/-/admin_search'
        data: {search: @teacherEmail}
        success: @fetchCompleteUser
        error: (data) => console.log arguments
        
    displayReport: (e) ->
      new OutcomeReportResult({
        @teacherEmail
        @teacherFullName
        @accountManagerFullName
        @schoolNameAndAddress
        @teacher # toJSON'd
        @trialRequest # toJSON'd
        @startDate # string YYYY-MM-DD
        @endDate # string YYYY-MM-DD
        classrooms: @classrooms.filter (c) => @isClassroomSelected[c._id]
        courses: @courses.filter (c) => @isCourseSelected[c._id]
      })
    
    fetchCompleteUser: (data) ->
      if data.length isnt 1
        noty text: "Didn't find exactly one such user"
        return
      user = new User(data[0])
      user.fetch()
      user.once 'sync', (fullData) =>
        @teacher = fullData.toJSON()
        @fetchTrialRequest()
        @fetchClassrooms()
        @fetchCourses()
    
    fetchTrialRequest: ->
      trialRequests = new TrialRequests()
      trialRequests.fetchByApplicant(@teacher._id)
      trialRequests.once 'sync', =>
        @trialRequest = trialRequests.models[0].toJSON()

    fetchClassrooms: ->
      classrooms = new Classrooms()
      classrooms.fetchByOwner(@teacher._id)
      classrooms.once 'sync', =>
        @classrooms = classrooms.toJSON()

    fetchCourses: ->
      courseInstances = new CourseInstances()
      courseInstances.fetchByOwner(@teacher._id)
      courseInstances.once 'sync', =>
        courses = new Courses()
        courses.fetch()
        courses.once 'sync', =>
          Vue.set @$data, 'courses', courseInstances.map (courseInstance) =>
            courses.get(courseInstance.get('courseID')).toJSON()

  created: ->
    if @accountManager.firstName && @accountManager.lastName
      @accountManagerFullName = "#{@accountManager.firstName} #{@accountManager.lastName}"
    else
      @accountManagerFullName = @accountManager.name
