CocoView = require 'views/kinds/CocoView'
template = require 'templates/game-menu/guide-view'
{me} = require 'lib/auth'
ThangType = require 'models/ThangType'

module.exports = class GuideView extends CocoView
  id: 'guide-view'
  className: 'tab-pane'
  template: template

  getRenderData: (context={}) ->
    context = super(context)
    context

  afterRender: ->
    super()
