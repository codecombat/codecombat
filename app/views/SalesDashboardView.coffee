RootView = require 'views/core/RootView'
template = require 'templates/sales-dashboard-view'
SkippedContacts = require 'collections/SkippedContacts'
User = require 'models/User'

vueTemplate = """

<div>
  Yay stuff
  {{message}}

    <div class="container">
      <ol class="skipped-contacts" v-if="skippedContacts">
        <li class="skipped-contact" v-for="skippedContact in skippedContacts">

          id: {{ skippedContact._id }}
          <h2 v-if="skippedContact && skippedContact.trialRequest">
            {{skippedContact.trialRequest.properties.email}}
          </h2>
        </li>
      </ol>
    </div>
</div>

"""

module.exports = class SalesDashboardView extends RootView
  id: 'sales-dashboard-view'
  template: template
  vueTemplate: vueTemplate

  events:
    'click .archive-contact': 'onClickArchiveContact'
    'click .unarchive-contact': 'onClickUnarchiveContact'

  initialize: ->
    @skippedContacts = new SkippedContacts()
    @listenTo @skippedContacts, 'sync change update', ->
      @render()
      # @skippedContacts.each (skippedContact) =>
      #   skippedContact.user = new User({ _id: skippedContact.get('trialRequest').applicant })
      #   skippedContact.user.fetch()
      #   @listenTo skippedContact.user, 'sync', =>
      #     # console.log 'User sync:', skippedContact.user
      #     @render()

    @skippedContacts.fetch()

  afterRender: ->
    @vue = new Vue({
      el: @$el.find('#sales-dashboard-view-2')[0]
      template: @vueTemplate
      data: {
        message: 'Hello!'
        skippedContacts: @skippedContacts.toJSON()
      }
    })
    console.log @vue
    super(arguments...)

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
      console.log {user}
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
