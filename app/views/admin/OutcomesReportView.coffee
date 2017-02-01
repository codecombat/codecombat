RootView = require 'views/core/RootView'
template = require 'templates/base-flat'
User = require 'models/User'
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
    me: me.toJSON()
    teacherEmail: 'phoenixjeliot@gmail.com'
    teacher: null
  computed:
    teacherFullName: ->
      if teacher
        if teacher.firstName && teacher.lastName
          return "#{teacher.firstName} #{teacher.lastName}"
        else
          return teacher.name
    accountManagerFullName: ->
      if me.firstName && me.lastName
        return "#{me.firstName} #{me.lastName}"
      else
        return me.name
  methods:
    submitEmail: (e) ->
      e.preventDefault
      console.log @
      $.ajax
        type: 'POST',
        url: '/db/user/-/admin_search'
        data: {search: @teacherEmail}
        success: (data) =>
          if data.length isnt 1
            noty text: "Didn't find exactly one such user"
            return
          user = new User(data[0])
          user.fetch()
          user.once 'sync', (fullData) =>
            @teacher = fullData.toJSON()
            console.log @teacher
        error: (data) => console.log arguments
