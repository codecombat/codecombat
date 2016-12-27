RootView = require 'views/core/RootView'
template = require 'templates/sales-dashboard-view'
SkippedContacts = require 'collections/SkippedContacts'

module.exports = class SalesDashboardView extends RootView
  id: 'sales-dashboard-view'
  template: template

  events:
    'click .archive-contact': 'onClickArchiveContact'
    'click .unarchive-contact': 'onClickUnarchiveContact'

  initialize: ->
    @skippedContacts = new SkippedContacts()
    @listenTo @skippedContacts, 'sync change update', ->
      @render()
      console.log arguments
    @supermodel.trackRequest @skippedContacts.fetch()

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
