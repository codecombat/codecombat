require('app/styles/admin/skipped-contacts-view.sass')
RootComponent = require 'views/core/RootComponent'
template = require 'templates/base-flat'
co = require('co')
api = require 'core/api'
FlatLayout = require 'core/components/FlatLayout'

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
      if @skippedContact.trialRequest?.properties
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

    # Optional TODO: Reconcile where these kinds of model-y calculations should go (API? the view?)
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
      if @skippedContact.zpContact
        zpContact = @skippedContact.zpContact
        query = "name:\"#{zpContact.organization}\""
        if (zpContact.nces_school_id)
          query = "custom.demo_nces_id:\"#{zpContact.nces_school_id}\""
        else if (zpContact.nces_district_id)
          query = "custom.demo_nces_district_id:\"#{zpContact.nces_district_id}\" custom.demo_nces_id:\"\" custom.demo_nces_name:\"\""
        return query

    queryURL: ->
      "https://app.close.io/search/" + encodeURIComponent(@queryString)

  methods:
    onClickArchiveContact: (e) ->
      archived = true
      @$store.dispatch('page/archiveContact', {@skippedContact, archived})
      # @$emit('archiveContact', @skippedContact, archived)
    onClickUnarchiveContact: (e) ->
      archived = false
      @$store.dispatch('page/archiveContact', {@skippedContact, archived})
      # @$emit('archiveContact', @skippedContact, archived)

SkippedContactsComponent = Vue.extend
  template: require('templates/admin/skipped-contacts/skipped-contacts-view')()
  data: ->
    sortOrder: 'date (descending)'
    showArchived: false
    showTrialRequestContacts: true
    showZenProspectContacts: true
    searchInput: ''
  computed:
    _.assign({},
      Vuex.mapState('page', ['skippedContacts', 'users']),
      Vuex.mapGetters('page', ['numArchivedUsers']),
      sortedContacts: (state) ->
        switch state.sortOrder
          when 'date (ascending)'
            return _(state.skippedContacts).sortBy((s) -> s.dateCreated).value()
          when 'date (descending)'
            return _(state.skippedContacts).sortBy((s) -> s.dateCreated).reverse().value()
          when 'email'
            return _(state.skippedContacts).sortBy((s) -> s.trialRequest?.properties?.email).value()
          when 'archived'
            return _(state.skippedContacts).sortBy((s) -> !!s.archived).reverse().value()
          when 'unarchived'
            return _(state.skippedContacts).sortBy((s) -> !!s.archived).value()
          else
            return state.skippedContacts
    )
  methods:
    isContactShown: (contact) ->
      return @matchesFilter(contact) if not _.isEmpty(@searchInput)
      (@showArchived or not contact.archived) and
        ((@showTrialRequestContacts and contact.trialRequest) or
         (@showZenProspectContacts and contact.zpContact))
    matchesFilter: (contact) ->
      _.contains(contact.email, @searchInput)
  components:
    'skipped-contact-info': SkippedContactInfo
    'flat-layout': FlatLayout
  created: co.wrap ->
    try
      skippedContacts = yield api.skippedContacts.getAll()
      @$store.commit('page/loadContacts', skippedContacts)
      yield skippedContacts.map co.wrap (skippedContact) =>
        userHandle = skippedContact.trialRequest?.applicant
        return unless userHandle
        user = yield api.users.getByHandle(userHandle)
        @$store.commit('page/addUser', { skippedContact , user })
    catch e
      @$store.commit('addPageError', e)

store = require('core/store')

module.exports = class SkippedContactsView extends RootComponent
  id: 'skipped-contacts-view'
  template: template
  VueComponent: SkippedContactsComponent
  vuexModule: -> {
    namespaced: true
    state:
      skippedContacts: []
      users: {}
    actions:
      archiveContact: ({ commit, state }, {skippedContact, archived}) ->
        newContact = _.assign({}, skippedContact, {archived})
        api.skippedContacts.put(newContact).then ->
          commit('archiveContact', {skippedContact, archived})
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
  }
