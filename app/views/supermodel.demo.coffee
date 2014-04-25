CocoView = require 'views/kinds/CocoView'
template = require 'templates/supermodel.demo'
User = require 'models/User'

module.exports = class UnnamedView extends CocoView
  id: "supermodel-demo-view"
  template: template

  constructor: (options) ->
    super(options)
    @load()

  load: ->
    @supermodel.addModelResource(new User(me.id))

#  getRenderData: ->
#    c = super()
#    c

#  destroy: ->
#    super()