require('app/styles/privacy.sass')
RootView = require 'views/core/RootView'
template = require 'templates/privacy'

module.exports = class PrivacyView extends RootView
  id: 'privacy-view'
  template: template

  afterRender: ->
    super()
    if _.contains(location.href, '#')
      _.defer =>
        # Remind the browser of the fragment in the URL, so it jumps to the right section.
        location.href = location.href
