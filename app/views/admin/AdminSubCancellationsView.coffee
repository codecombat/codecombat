RootView = require 'views/core/RootView'
CocoCollection = require 'collections/CocoCollection'
utils = require 'core/utils'

module.exports = class AdminSubCancellationsView extends RootView
  id: 'admin-sub-cancellations-view'
  template: require 'templates/admin/admin-sub-cancellations'

  initialize: ->
    return super() unless me.isAdmin()
    @objectIdToDate = utils.objectIdToDate
    @limit = utils.getQueryVariable('limit', 100)
    url = '/db/analytics.log.event?filter[event]="Unsubscribe End"&conditions[sort]="-_id"&conditions[limit]=' + @limit
    Promise.resolve($.get(url))
    .then (@cancelEvents) =>
      @render?()
    super()
