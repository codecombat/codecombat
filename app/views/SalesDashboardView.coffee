RootView = require 'views/core/RootView'
template = require 'templates/sales-dashboard-view'
SkippedContacts = require 'collections/SkippedContacts'

module.exports = class SalesDashboardView extends RootView
  id: 'sales-dashboard-view'
  template: template

  initialize: ->
    @skippedContacts = new SkippedContacts()
    @listenTo @skippedContacts, 'sync', ->
      console.log arguments
    @supermodel.trackRequest @skippedContacts.fetch()
