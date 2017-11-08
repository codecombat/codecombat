require('app/styles/play/menu/save-load-view.sass')
CocoView = require 'views/core/CocoView'
template = require 'templates/play/menu/save-load-view'
{me} = require 'core/auth'
ThangType = require 'models/ThangType'

module.exports = class SaveLoadView extends CocoView
  id: 'save-load-view'
  className: 'tab-pane'
  template: template

  events:
    'change #save-granularity-toggle input': 'onSaveGranularityChanged'

  afterRender: ->
    super()

  onSaveGranularityChanged: (e) ->
    @playSound 'menu-button-click'
    toShow = $(e.target).val()
    @$el.find('.save-list, .save-pane').hide()
    @$el.find('.save-list.' + toShow + ', .save-pane.' + toShow).show()
