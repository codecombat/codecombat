RootView = require 'views/core/RootView'
template = require 'templates/about'

module.exports = class AboutView extends RootView
  id: 'about-view'
  template: template

  logoutRedirectURL: false
  
  afterRender: ->
    super(arguments...)
    args =
      offset:
        top: ->
          console.log "top called"
          return 200
    $('#nav-container').affix(args)
    console.log args
    console.log "afterRender called"
    