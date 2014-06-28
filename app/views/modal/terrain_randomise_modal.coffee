ModalView = require 'views/kinds/ModalView'
template = require 'templates/modal/terrain_randomise'
CocoModel = require 'models/CocoModel'

presets = {
  'dungeon': {
    'type':'dungeon'
    'borders':['Dungeon Wall']
    'floors':['Dungeon Floor']
    'decorations':[]
  }
}

sizes = {
  'small': {
    'x':80
    'y':68
  }
  'large': {
    'x':160
    'y':136
  }
  'floorSize': {
    'x':20
    'y':20
  }
  'borderSize': {
    'x':4
    'y':4
  }
}

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
    target = $(e.target)
    presetType = target.attr 'data-preset-type'
    presetSize = target.attr 'data-preset-size'
    @randomiseThangs presetType, presetSize

    Backbone.Mediator.publish('randomise:terrain-generated', 
      'thangs': @thangs
    )

  randomiseThangs: (presetName, presetSize) ->
    preset = presets[presetName]
    presetSize = sizes[presetSize]
    @thangs = []
    @randomiseFloor preset, presetSize
    @randomiseBorder preset, presetSize

  randomiseFloor: (preset, presetSize) ->
    for i in _.range(0, presetSize.x, sizes.floorSize.x)
      for j in _.range(0, presetSize.y, sizes.floorSize.y)
        @thangs.push {
          'id': @getRandomThang(preset.floors)
          'pos': {
            'x': i
            'y': j
          }
        }

  randomiseBorder: (preset, presetSize) ->
    for i in _.range(0-sizes.floorSize.x/2+sizes.borderSize.x, presetSize.x-sizes.floorSize.x/2, sizes.borderSize.x)
      @thangs.push {
        'id': @getRandomThang(preset.borders)
        'pos': {
          'x': i
          'y': 0-sizes.floorSize.x/2
        }
      }
      @thangs.push {
        'id': @getRandomThang(preset.borders)
        'pos': {
          'x': i
          'y': presetSize.y - sizes.borderSize.y
        }
      }

    for i in _.range(0-sizes.floorSize.y/2, presetSize.y-sizes.borderSize.y, sizes.borderSize.y)
      @thangs.push {
        'id': @getRandomThang(preset.borders)
        'pos': {
          'x': 0-sizes.floorSize.x/2+sizes.borderSize.x
          'y': i
        }
      }
      @thangs.push {
        'id': @getRandomThang(preset.borders)
        'pos': {
          'x': presetSize.x - sizes.borderSize.x - sizes.floorSize.x/2
          'y': i
        }
      }

  getRandomThang: (thangList) ->
    return thangList[_.random(0, thangList.length-1)]
    
  getRenderData: ->
    c = super()
    models = _.values CocoModel.backedUp
    models = (m for m in models when m.hasLocalChanges())
    c.models = models
    c

  onHidden: ->
    location.reload() if @reloadOnClose
