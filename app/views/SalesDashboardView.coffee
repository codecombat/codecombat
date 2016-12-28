RootView = require 'views/core/RootView'
template = require 'templates/base-flat'
SkippedContacts = require 'collections/SkippedContacts'
User = require 'models/User'

SalesDashboardComponent = Vue.extend({
  template: require('templates/sales-dashboard/sales-dashboard-view')()
  data: ->
    skippedContacts: []
})

module.exports = class SalesDashboardView extends RootView
  id: 'sales-dashboard-view'
  template: template

  initialize: ->
    @debouncedRender = _.debounce(@render, 0)
    @skippedContacts = new SkippedContacts()
    @listenTo @skippedContacts, 'change update', ->
      # @debouncedRender()
    @listenToOnce @skippedContacts, 'sync', ->
      console.log 'SkippedContacts Sync!'
      @debouncedRender()
      @skippedContacts.each (skippedContact) =>
        skippedContact.user = new User({ _id: skippedContact.get('trialRequest').applicant })
        skippedContact.user.fetch()
        skippedContact.set('queryString', @queryString(skippedContact))
        @listenTo skippedContact.user, 'sync', =>
          console.log 'User sync!'
          skippedContact.set('noteData', @noteData(skippedContact))
          # @debouncedRender()

    @skippedContacts.fetch()

  afterRender: ->
    console.log "Rendering!"
    @vueComponent?.$destroy() # TODO: Don't recreate this component every time things update
    skippedContacts = @skippedContacts
    @vueComponent = new SalesDashboardComponent({
      el: @$el.find('#site-content-area')[0]
      data: {
        skippedContacts: @skippedContacts.toJSON()
      }
      computed: {
        # TODO
      }
      methods: {
        onClickArchiveContact: @onClickArchiveContact.bind(@)
        onClickUnarchiveContact: @onClickUnarchiveContact.bind(@)
        updateVueFromCollection: _.debounce((collection) ->
          @skippedContacts = collection.toJSON()
        , 10)
        updateVueFromModel: _.debounce((model) ->
          index = _.findIndex(@skippedContacts, (s) -> s._id is model.id)
          Vue.set(@skippedContacts, index, model.toJSON())
        , 10)
      }
      created: ->
        # Two-way bind backbone model to data http://jsfiddle.net/x1jeawzv/2/
        # @$watch 'skippedContacts', (val) ->
        #   console.log "Setting model based on vue"
        #   skippedContacts.set(val)
        skippedContacts.on 'update', @updateVueFromCollection
        skippedContacts.on 'change', @updateVueFromModel
      beforeDestroy: ->
        skippedContacts.off null, @updateVueFromCollection
        skippedContacts.off null, @updateVueFromModel
    })
    super(arguments...)

  queryString: (skippedContact) ->
    if skippedContact.get('trialRequest')
      trialRequest = skippedContact.get('trialRequest')
      leadName = trialRequest.properties.nces_name or trialRequest.properties.organization or trialRequest.properties.school or trialRequest.properties.district or trialRequest.properties.nces_district or trialRequest.properties.email
      query = "name:\"#{leadName}\"";
      if (trialRequest.properties.nces_school_id)
        query = "custom.demo_nces_id:\"#{trialRequest.properties.nces_school_id}\"";
      else if (trialRequest.properties.nces_district_id)
        query = "custom.demo_nces_district_id:\"#{trialRequest.properties.nces_district_id}\" custom.demo_nces_id:\"\" custom.demo_nces_name:\"\"";
      return query

  # TODO: Clean this up; it's hastily copied/modified from updateCloseIoLeads.js
  # TODO: Figure out how to make this less redundant with that script
  noteData: (skippedContact) ->
    noteData = ""
    skippedContactAttrs = skippedContact.attributes
    if skippedContactAttrs.trialRequest.properties
      props = skippedContactAttrs.trialRequest.properties
      if (props.name)
        noteData += "#{props.name}\n"
      if (props.email)
        noteData += "demo_email: #{props.email.toLowerCase()}\n"
      if (skippedContactAttrs.trialRequest.created)
        noteData += "demo_request: #{skippedContactAttrs.trialRequest.created}\n"
      if (props.educationLevel)
        noteData += "demo_educationLevel: #{props.educationLevel.join(', ')}\n"
      for prop in props
        continue if (['email', 'educationLevel', 'created'].indexOf(prop) >= 0)
        noteData += "demo_#{prop}: #{props[prop]}\n"
    noteData += "intercom_url: #{skippedContactAttrs.intercomUrl}\n" if (skippedContactAttrs.intercomUrl)
    noteData += "intercom_lastSeen: #{skippedContactAttrs.intercomLastSeen}\n" if (skippedContactAttrs.intercomLastSeen)
    noteData += "intercom_sessionCount: #{skippedContactAttrs.intercomSessionCount}\n" if (skippedContactAttrs.intercomSessionCount)

    if (skippedContact.user)
      user = skippedContact.user.attributes
      noteData += "coco_userID: #{user._id}\n"
      noteData += "coco_firstName: #{user.firstName}\n" if (user.firstName)
      noteData += "coco_lastName: #{user.lastName}\n" if (user.lastName)
      noteData += "coco_name: #{user.name}\n" if (user.name)
      noteData += "coco_email: #{user.emailLower}\n" if (user.emaillower)
      noteData += "coco_gender: #{user.gender}\n" if (user.gender)
      noteData += "coco_lastLevel: #{user.lastLevel}\n" if (user.lastLevel)
      noteData += "coco_role: #{user.role}\n" if (user.role)
      noteData += "coco_schoolName: #{user.schoolName}\n" if (user.schoolName)
      noteData += "coco_gamesCompleted: #{user.stats.gamesCompleted}\n" if (user.stats && user.stats.gamesCompleted)
      noteData += "coco_preferredLanguage: #{user.preferredLanguage || 'en-US'}\n"
    if (skippedContact.numClassrooms)
      noteData += "coco_numClassrooms: #{skippedContact.numClassrooms}\n"
    if (skippedContact.numStudents)
      noteData += "coco_numStudents: #{skippedContact.numStudents}\n"
    return noteData


  onClickArchiveContact: (e) ->
    e.preventDefault()
    contactId = $(e.currentTarget).data('contact-id')
    contact = @skippedContacts.get(contactId)
    contact.set({
      archived: true
    })
    contact.save()

  onClickUnarchiveContact: (e) ->
    e.preventDefault()
    contactId = $(e.currentTarget).data('contact-id')
    contact = @skippedContacts.get(contactId)
    contact.set({
      archived: false
    })
    contact.save()
