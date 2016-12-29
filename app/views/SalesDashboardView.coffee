RootView = require 'views/core/RootView'
template = require 'templates/base-flat'
SkippedContacts = require 'collections/SkippedContacts'
User = require 'models/User'
# TODO: Stop using old co, switch to the kind that uses co.wrap

skippedContactApi = {
  setArchived: (_id, archived) ->
    $.ajax({
      url: '/db/skipped-contact/' + _id
      type: 'PUT'
      data: {
        _id
        archived
      }
    })
}

SalesDashboardComponent = Vue.extend({
  template: require('templates/sales-dashboard/sales-dashboard-view')()
  data: ->
    skippedContacts: []
})

module.exports = class SalesDashboardView extends RootView
  id: 'sales-dashboard-view'
  template: template

  afterRender: ->
    console.log "Rendering!"
    @vueComponent?.$destroy() # TODO: Don't recreate this component every time things update
    skippedContacts = @skippedContacts
    @vueComponent = new SalesDashboardComponent({
      el: @$el.find('#site-content-area')[0]
      data: {
        skippedContacts: []
        queryString: ''
      }
      computed: {
        # TODO
      }
      methods: {
        onClickArchiveContact: co (e) ->
          e.preventDefault()
          contactId = $(e.currentTarget).data('contact-id')
          index = _.findIndex(@skippedContacts, (s) -> s._id is contactId)
          contact = @skippedContacts[index]
          yield skippedContactApi.setArchived(contactId, true)
          Vue.set(@skippedContacts, index, _.assign({}, contact, {archived: true}))
        onClickUnarchiveContact: co (e) ->
          e.preventDefault()
          contactId = $(e.currentTarget).data('contact-id')
          index = _.findIndex(@skippedContacts, (s) -> s._id is contactId)
          contact = @skippedContacts[index]
          yield skippedContactApi.setArchived(contactId, false)
          Vue.set(@skippedContacts, index, _.assign({}, contact, {archived: false}))

        updateVueFromCollection: _.debounce((collection) ->
          console.log 'update from collection'
          @skippedContacts = collection.toJSON()
        , 10)
        updateVueFromModel: _.debounce((model) ->
          index = _.findIndex(@skippedContacts, (s) -> s._id is model.id)
          Vue.set(@skippedContacts, index, model.toJSON())
        , 10)
        getQueryString: (skippedContact) ->
          if skippedContact.trialRequest
            trialRequest = skippedContact.trialRequest
            leadName = trialRequest.properties.nces_name or trialRequest.properties.organization or trialRequest.properties.school or trialRequest.properties.district or trialRequest.properties.nces_district or trialRequest.properties.email
            query = "name:\"#{leadName}\"";
            if (trialRequest.properties.nces_school_id)
              query = "custom.demo_nces_id:\"#{trialRequest.properties.nces_school_id}\"";
            else if (trialRequest.properties.nces_district_id)
              query = "custom.demo_nces_district_id:\"#{trialRequest.properties.nces_district_id}\" custom.demo_nces_id:\"\" custom.demo_nces_name:\"\"";
            return query
        # TODO: Clean this up; it's hastily copied/modified from updateCloseIoLeads.js
        # TODO: Figure out how to make this less redundant with that script
        getNoteData: (skippedContact) ->
          noteData = ""
          skippedContactAttrs = skippedContact
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
      }
      created: co ->
        # Two-way bind backbone model to data http://jsfiddle.net/x1jeawzv/2/
        # @$watch 'skippedContacts', (val) ->
        #   console.log "Setting model based on vue"
        #   skippedContacts.set(val)
        # skippedContacts.on 'update', @updateVueFromCollection
        # skippedContacts.on 'change', @updateVueFromModel
        console.log "yay"
        skippedContacts = new SkippedContacts()
        yield skippedContacts.fetch()
        @skippedContacts = skippedContacts.toJSON()
        yield @skippedContacts.map co (skippedContact) =>
          user = new User({ _id: skippedContact.trialRequest.applicant })
          index = _.findIndex(@skippedContacts, (s) -> s._id is skippedContact._id)
          Vue.set(@skippedContacts, index, _.assign({}, @skippedContacts[index], {queryString: @getQueryString(skippedContact)}))
          yield user.fetch()
          # TODO: How do we pass this down into the components?
          Vue.set(@skippedContacts, index, _.assign({}, @skippedContacts[index], {user: user}))
          Vue.set(@skippedContacts, index, _.assign({}, @skippedContacts[index], {noteData: @getNoteData(skippedContact)}))
    })
    super(arguments...)
