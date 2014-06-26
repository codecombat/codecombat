ModalView = require 'views/kinds/ModalView'
template = require 'templates/modal/terrain_randomise'
CocoModel = require 'models/CocoModel'

module.exports = class TerrainRandomiseModal extends ModalView
  id: 'terrain-randomise-modal'
  template: template
  thangs = []

  events:
    'click .choose-option': 'onRandomise'

  onRevertModel: (e) ->
    id = $(e.target).val()
    CocoModel.backedUp[id].revert()
    $(e.target).closest('tr').remove()
    @reloadOnClose = true

  onRandomise: (e) ->
    @thangs = []
    @thangs.push {
      'id':'Grass01'
      'pos':{
        'x':20
        'y':20
        }
      }
    Backbone.Mediator.publish('randomise:terrain-generated', 
      'thangs': @thangs
    )
    
  getRenderData: ->
    c = super()
    models = _.values CocoModel.backedUp
    models = (m for m in models when m.hasLocalChanges())
    c.models = models
    c

  onHidden: ->
    location.reload() if @reloadOnClose
