RootView = require 'views/core/RootView'

module.exports = class RestrictedToTeachersView extends RootView
  id: 'restricted-to-teachers-view'
  template: require 'templates/teachers/restricted-to-teachers-view'

  initialize: ->
    me.getClientCreatorPermissions()?.then(() => @render?())
    window.tracker?.trackEvent 'Restricted To Teachers Loaded', category: 'Students', ['Mixpanel']
