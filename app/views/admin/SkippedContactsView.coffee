RootView = require 'views/core/RootView'
template = require 'templates/base-flat'
SkippedContacts = require 'collections/SkippedContacts'
User = require 'models/User'
require('vendor/co')
require('vendor/vue')
require('vendor/vuex')

skippedContactApi =
  setArchived: (_id, archived) ->
    $.ajax({
      url: '/db/skipped-contact/' + _id
      type: 'PUT'
      data: {
        _id
        archived
      }
    })

SkippedContactInfo =
  template: require('templates/admin/skipped-contacts/skipped-contact-info')()
  props:
    skippedContact:
      type: Object
      default: -> {}
    user:
      type: Object
      default: -> undefined
  computed:
    noteData: ->
      # TODO: Clean this up; it's hastily copied/modified from updateCloseIoLeads.js
      # TODO: Figure out how to make this less redundant with that script
      noteData = ""
      @skippedContact
      if @skippedContact.trialRequest.properties
        props = @skippedContact.trialRequest.properties
        if (props.name)
          noteData += "#{props.name}\n"
        if (props.email)
          noteData += "demo_email: #{props.email.toLowerCase()}\n"
        if (@skippedContact.trialRequest.created)
          noteData += "demo_request: #{@skippedContact.trialRequest.created}\n"
        if (props.educationLevel)
          noteData += "demo_educationLevel: #{props.educationLevel.join(', ')}\n"
        for prop in props
          continue if (['email', 'educationLevel', 'created'].indexOf(prop) >= 0)
          noteData += "demo_#{prop}: #{props[prop]}\n"
      noteData += "intercom_url: #{@skippedContact.intercomUrl}\n" if (@skippedContact.intercomUrl)
      noteData += "intercom_lastSeen: #{@skippedContact.intercomLastSeen}\n" if (@skippedContact.intercomLastSeen)
      noteData += "intercom_sessionCount: #{@skippedContact.intercomSessionCount}\n" if (@skippedContact.intercomSessionCount)

      if @user
        noteData += "coco_userID: #{@user._id}\n"
        noteData += "coco_firstName: #{@user.firstName}\n" if (@user.firstName)
        noteData += "coco_lastName: #{@user.lastName}\n" if (@user.lastName)
        noteData += "coco_name: #{@user.name}\n" if (@user.name)
        noteData += "coco_email: #{@user.emailLower}\n" if (@user.emaillower)
        noteData += "coco_gender: #{@user.gender}\n" if (@user.gender)
        noteData += "coco_lastLevel: #{@user.lastLevel}\n" if (@user.lastLevel)
        noteData += "coco_role: #{@user.role}\n" if (@user.role)
        noteData += "coco_schoolName: #{@user.schoolName}\n" if (@user.schoolName)
        noteData += "coco_gamesCompleted: #{@user.stats.gamesCompleted}\n" if (@user.stats && @user.stats.gamesCompleted)
        noteData += "coco_preferredLanguage: #{@user.preferredLanguage || 'en-US'}\n"
      if (@numClassrooms) # TODO compute this
        noteData += "coco_numClassrooms: #{skippedContact.numClassrooms}\n"
      if (@numStudents) # TODO compute this
        noteData += "coco_numStudents: #{skippedContact.numStudents}\n"
      return noteData

    queryString: ->
      if @skippedContact.trialRequest
        trialRequest = @skippedContact.trialRequest
        leadName = trialRequest.properties.nces_name or trialRequest.properties.organization or trialRequest.properties.school or trialRequest.properties.district or trialRequest.properties.nces_district or trialRequest.properties.email
        query = "name:\"#{leadName}\""
        if (trialRequest.properties.nces_school_id)
          query = "custom.demo_nces_id:\"#{trialRequest.properties.nces_school_id}\""
        else if (trialRequest.properties.nces_district_id)
          query = "custom.demo_nces_district_id:\"#{trialRequest.properties.nces_district_id}\" custom.demo_nces_id:\"\" custom.demo_nces_name:\"\""
        return query

    queryURL: ->
      "https://app.close.io/search/" + encodeURIComponent(@queryString)

  methods:
    onClickArchiveContact: (e) ->
      archived = true
      @$store.dispatch('archiveContact', {@skippedContact, archived})
      # @$emit('archiveContact', @skippedContact, archived)
    onClickUnarchiveContact: (e) ->
      archived = false
      @$store.dispatch('archiveContact', {@skippedContact, archived})
      # @$emit('archiveContact', @skippedContact, archived)

SkippedContactsComponent = Vue.extend
  template: require('templates/admin/skipped-contacts/skipped-contacts-view')()
  data: ->
    sortOrder: 'date (ascending)'
    showArchived: true
  computed:
    _.assign({},
      Vuex.mapState(['skippedContacts', 'users']),
      Vuex.mapGetters(['numArchivedUsers']),
      sortedContacts: (state) ->
        switch state.sortOrder
          when 'date (ascending)'
            return _(state.skippedContacts).sortBy((s) -> s.trialRequest.created).value()
          when 'date (descending)'
            return _(state.skippedContacts).sortBy((s) -> s.trialRequest.created).reverse().value()
          when 'email'
            return _(state.skippedContacts).sortBy((s) -> s.trialRequest.properties.email).value()
          when 'archived'
            return _(state.skippedContacts).sortBy((s) -> !!s.archived).reverse().value()
          when 'unarchived'
            return _(state.skippedContacts).sortBy((s) -> !!s.archived).value()
          else
            return state.skippedContacts
    )
  components:
    'skipped-contact-info': SkippedContactInfo
  created: co.wrap ->
    skippedContacts = new SkippedContacts()
    yield skippedContacts.fetch()
    skippedContacts = skippedContacts.toJSON()
    @$store.commit('loadContacts', skippedContacts)
    yield skippedContacts.map co.wrap (skippedContact) =>
      user = new User({ _id: skippedContact.trialRequest.applicant })
      index = _.findIndex(@skippedContacts, (s) -> s._id is skippedContact._id)
      yield user.fetch()
      @$store.commit('addUser', { skippedContact , user: user.toJSON() })

module.exports = class SkippedContactsView extends RootView
  id: 'skipped-contacts-view'
  template: template

  initialize: ->
    super(arguments...)
    # Vuex Store
    @store = new Vuex.Store({
      state:
        skippedContacts: []
        users: {}
      actions:
        archiveContact: ({ commit, state }, {skippedContact, archived}) ->
          skippedContactApi.setArchived(skippedContact._id, archived).then ->
            commit('archiveContact', {skippedContact, archived})
      strict: not application.isProduction()
      mutations:
        archiveContact: (state, { skippedContact, archived }) ->
          index = _.findIndex(state.skippedContacts, (s) -> s._id is skippedContact._id)
          oldContact = state.skippedContacts[index]
          Vue.set(state.skippedContacts, index, _.assign({}, oldContact, { archived }))
        addUser: (state, { skippedContact, user }) ->
          Vue.set(state.users, skippedContact._id, user)
        loadContacts: (state, skippedContacts) ->
          state.skippedContacts = skippedContacts
      getters:
        numArchivedUsers: (state) ->
          _.countBy(state.skippedContacts, (contact) -> contact.archived)[true]
    })


  afterRender: ->
    @vueComponent?.$destroy() # TODO: Don't recreate this component every time things update
    @vueComponent = new SkippedContactsComponent({
      el: @$el.find('#site-content-area')[0]
      store: @store
    })

    super(arguments...)
