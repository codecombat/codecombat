require('app/styles/teachers/ap-cs-principles.sass')
RootView = require 'views/core/RootView'

module.exports = class ApCsPrinciplesView extends RootView
  id: 'ap-cs-principles-view'
  template: require 'templates/teachers/ap-cs-principles-view'

  getTitle: -> 'AP CS Principles'

  initialize: ->
    me.getClientCreatorPermissions()?.then(() => @render?())
