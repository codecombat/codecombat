RootView = require 'views/core/RootView'
template = require 'templates/teachers'

module.exports = class TeachersView extends RootView
  id: 'teachers-view'
  template: template

  constructor: ->
    super()

    # Redirect to HoC version of /courses/teachers until we update the /teachers landing page
    application.router.navigate "/courses/teachers?hoc=true", trigger: true
