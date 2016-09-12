RootView = require 'views/core/RootView'
Prepaids = require 'collections/Prepaids'

module.exports = class ResourceHubView extends RootView
  id: 'resource-hub-view'
  template: require 'templates/teachers/resource-hub-view'

  getTitle: -> return $.i18n.t('teacher.resource_hub')

  initialize: (options) ->
    unless me.isAnonymous()
      @prepaids = new Prepaids()
      @supermodel.trackRequest(@prepaids.fetchByCreator(me.id))
    super(options)

  onLoaded: ->
    # Grant access for current or future licenses
    today = new Date().toISOString()
    for prepaid in @prepaids.models when prepaid.get('type') is 'course'
      if today.localeCompare(prepaid.get('endDate') ? '') < 0
        @paidAccess = true
        break
    super()
