CocoView = require 'views/kinds/CocoView'
template = require 'templates/game-menu/save-load-view'
{me} = require 'lib/auth'
ThangType = require 'models/ThangType'

module.exports = class SaveLoadView extends CocoView
  id: 'save-load-view'
  className: 'tab-pane'
  template: template

  events:
    'change #save-granularity-toggle input': 'onSaveGranularityChanged'

  getRenderData: (context={}) ->
    context = super(context)
    context

  afterRender: ->
    super()

  onSaveGranularityChanged: (e) ->
    toShow = $(e.target).val()
    @$el.find('.save-list, .save-pane').hide()
    @$el.find('.save-list.' + toShow + ', .save-pane.' + toShow).show()
