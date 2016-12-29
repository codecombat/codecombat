RootView = require 'views/core/RootView'
template = require 'templates/base-flat'
SkippedContacts = require 'collections/SkippedContacts'
User = require 'models/User'
# TODO: Stop using old co, switch to the kind that uses co.wrap

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
  template: require('templates/sales-dashboard/skipped-contact-info')()
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
        query = "name:\"#{leadName}\"";
        if (trialRequest.properties.nces_school_id)
          query = "custom.demo_nces_id:\"#{trialRequest.properties.nces_school_id}\"";
        else if (trialRequest.properties.nces_district_id)
          query = "custom.demo_nces_district_id:\"#{trialRequest.properties.nces_district_id}\" custom.demo_nces_id:\"\" custom.demo_nces_name:\"\"";
        return query

  methods:
    onClickArchiveContact: (e) ->
      archived = true
      @$emit('archiveContact', @skippedContact, archived)
    onClickUnarchiveContact: (e) ->
      archived = false
      @$emit('archiveContact', @skippedContact, archived)

SalesDashboardComponent = Vue.extend
  template: require('templates/sales-dashboard/sales-dashboard-view')()
  data: ->
    skippedContacts: []
    users: {}
    showArchived: true
  computed:
    numArchivedUsers: ->
      _.countBy(@skippedContacts, (contact) -> contact.archived)[true]
  components:
    'skipped-contact-info': SkippedContactInfo
  methods:
    setShowArchived: (showArchived) ->
      @showArchived = showArchived
    archiveContact: co (skippedContact, archived) ->
      yield skippedContactApi.setArchived(skippedContact._id, archived)
      index = _.findIndex(@skippedContacts, (s) -> s._id is skippedContact._id)
      oldContact = @skippedContacts[index]
      Vue.set(@skippedContacts, index, _.assign({}, oldContact, { archived }))
  created: co ->
    skippedContacts = new SkippedContacts()
    yield skippedContacts.fetch()
    @skippedContacts = skippedContacts.toJSON()
    yield @skippedContacts.map co (skippedContact) =>
      user = new User({ _id: skippedContact.trialRequest.applicant })
      index = _.findIndex(@skippedContacts, (s) -> s._id is skippedContact._id)
      yield user.fetch()
      Vue.set(@users, skippedContact._id, user.toJSON())

module.exports = class SalesDashboardView extends RootView
  id: 'sales-dashboard-view'
  template: template

  afterRender: ->
    @vueComponent?.$destroy() # TODO: Don't recreate this component every time things update
    @vueComponent = new SalesDashboardComponent({
      el: @$el.find('#site-content-area')[0]
      })
    super(arguments...)
