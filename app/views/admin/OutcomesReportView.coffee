RootView = require 'views/core/RootView'
template = require 'templates/base-flat'
User = require 'models/User'
TrialRequest = require 'models/TrialRequest'
TrialRequests = require 'collections/TrialRequests'
require('vendor/co')
require('vendor/vue')
require('vendor/vuex')

module.exports = class OutcomesReportView extends RootView
  id: 'skipped-contacts-view'
  template: template

  initialize: ->
    super(arguments...)
    # Vuex Store
    @store = new Vuex.Store({
      state:
        {}
      actions:
        {}
      strict: not application.isProduction()
      mutations:
        {}
      getters:
        {}
    })

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
    teacherEmail: '583f580a9aa323940016b2ac'
    teacher: null
    trialRequest: null
    startDate: null
    endDate: moment(new Date()).format('YYYY-MM-DD')
  computed:
    teacherFullName: ->
      if @teacher
        if @teacher.firstName && @teacher.lastName
          return "#{@teacher.firstName} #{@teacher.lastName}"
        else
          return teacher.name
    accountManagerFullName: ->
      if @accountManager.firstName && @accountManager.lastName
        return "#{@accountManager.firstName} #{@accountManager.lastName}"
      else
        return @accountManager.name
    schoolNameAndAddress: -> @trialRequest?.properties.school
  methods:
    submitEmail: (e) ->
      e.preventDefault
      $.ajax
        type: 'POST',
        url: '/db/user/-/admin_search'
        data: {search: @teacherEmail}
        success: @fetchCompleteUser
        error: (data) => console.log arguments
    
    fetchCompleteUser: (data) ->
      if data.length isnt 1
        noty text: "Didn't find exactly one such user"
        return
      user = new User(data[0])
      user.fetch()
      user.once 'sync', (fullData) =>
        @teacher = fullData.toJSON()
        @fetchTrialRequest()
    
    fetchTrialRequest: ->
      trialRequests = new TrialRequests()
      trialRequests.fetchByApplicant(@teacher._id)
      trialRequests.once 'sync', =>
        @trialRequest = trialRequests.models[0].toJSON()
        @startDate = moment(new Date(@trialRequest.created)).format('YYYY-MM-DD')
