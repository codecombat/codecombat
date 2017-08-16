RootView = require 'views/core/RootView'

module.exports = class RestrictedToStudentsView extends RootView
  id: 'restricted-to-students-view'
  template: require 'templates/courses/restricted-to-students-view'

  initialize: ->
    window.tracker?.trackEvent 'Restricted To Students Loaded', category: 'Students', []
