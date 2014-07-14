ModalView = require 'views/kinds/ModalView'
template = require 'templates/editor/level/modal/terrain_randomize'
CocoModel = require 'models/CocoModel'

clusters = {
  'rocks': ['Rock 1', 'Rock 2', 'Rock 3', 'Rock 4', 'Rock 5', 'Rock Cluster 1', 'Rock Cluster 2', 'Rock Cluster 3']
  'trees': ['Tree 1', 'Tree 2', 'Tree 3', 'Tree 4']  
  'shrubs': ['Shrub 1', 'Shrub 2', 'Shrub 3']
  'houses': ['House 1', 'House 2', 'House 3', 'House 4']
  'animals': ['Cow', 'Horse']
  'wood': ['Firewood 1', 'Firewood 2', 'Firewood 3', 'Barrel']
  'farm': ['Farm']
}

presets = {
  # 'dungeon': {
  #   'type':'dungeon'
  #   'borders':['Dungeon Wall']
  #   'floors':['Dungeon Floor']
  #   'decorations':[]
  # }
  'grassy': {
    'type':'grassy'
    'borders':['Tree 1', 'Tree 2', 'Tree 3']
    'floors':['Grass01', 'Grass02', 'Grass03']
    'decorations': {
      'house': {
        'num':[1,2] #min-max
        'width': 20
        'height': 20
        'clusters': {
          'houses':[1,1]
          'trees':[1,2]
          'shrubs':[0,3]
          'rocks':[1,2]
        }
      }
      'farm': {
        'num':[1,2] #min-max
        'width': 20
        'height': 20
        'clusters': {
          'farm':[1,1]
          'shrubs':[2,3]
          'wood':[2,4]
          'animals':[2,3]
        }
      }
    }
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
    'thickness':2
  }
}

module.exports = class TerrainRandomizeModal extends ModalView
  id: 'terrain-randomize-modal'
  template: template
  thangs = []

  events:
    'click .choose-option': 'onRandomize'

  onRevertModel: (e) ->
    id = $(e.target).val()
    CocoModel.backedUp[id].revert()
    $(e.target).closest('tr').remove()
    @reloadOnClose = true

  onRandomize: (e) ->
    target = $(e.target)
    presetType = target.attr 'data-preset-type'
    presetSize = target.attr 'data-preset-size'
    @randomizeThangs presetType, presetSize
    Backbone.Mediator.publish('randomize:terrain-generated', 
      'thangs': @thangs
    )
    @hide()

  randomizeThangs: (presetName, presetSize) ->
    preset = presets[presetName]
    presetSize = sizes[presetSize]
    @thangs = []
    @randomizeFloor preset, presetSize
    @randomizeBorder preset, presetSize
    @randomizeDecorations preset, presetSize

  randomizeFloor: (preset, presetSize) ->
    for i in _.range(0, presetSize.x, sizes.floorSize.x)
      for j in _.range(0, presetSize.y, sizes.floorSize.y)
        @thangs.push {
          'id': @getRandomThang(preset.floors)
          'pos': {
            'x': i
            'y': j
          }
        }

  randomizeBorder: (preset, presetSize) ->
    for i in _.range(0-sizes.floorSize.x/2+sizes.borderSize.x, presetSize.x-sizes.floorSize.x/2, sizes.borderSize.x)
      for j in _.range(sizes.borderSize.thickness)
        @thangs.push {
          'id': @getRandomThang(preset.borders)
          'pos': {
            'x': i + _.random(-sizes.borderSize.x/2, sizes.borderSize.x/2)
            'y': 0 - sizes.floorSize.x/2 + _.random(-sizes.borderSize.x/2, sizes.borderSize.x/2)
          }
        }
        @thangs.push {
          'id': @getRandomThang(preset.borders)
          'pos': {
            'x': i + _.random(-sizes.borderSize.x/2, sizes.borderSize.x/2)
            'y': presetSize.y - sizes.borderSize.y + _.random(-sizes.borderSize.x/2, sizes.borderSize.x/2)
          }
        }

    for i in _.range(0-sizes.floorSize.y/2, presetSize.y-sizes.borderSize.y, sizes.borderSize.y)
      for j in _.range(3)
        @thangs.push {
          'id': @getRandomThang(preset.borders)
          'pos': {
            'x': 0-sizes.floorSize.x/2+sizes.borderSize.x + _.random(-sizes.borderSize.y/2, sizes.borderSize.y/2)
            'y': i + _.random(-sizes.borderSize.y/2, sizes.borderSize.y/2)
          }
        }
        @thangs.push {
          'id': @getRandomThang(preset.borders)
          'pos': {
            'x': presetSize.x - sizes.borderSize.x - sizes.floorSize.x/2 + _.random(-sizes.borderSize.y/2, sizes.borderSize.y/2)
            'y': i + _.random(-sizes.borderSize.y/2, sizes.borderSize.y/2)
          }
        }

  randomizeDecorations: (preset, presetSize)->
    for name, decoration of preset.decorations
      for num in _.range(_.random(decoration.num[0], decoration.num[1]))
        center = 
        {
          'x':_.random(decoration.width, presetSize.x - decoration.width), 
          'y':_.random(decoration.height, presetSize.y - decoration.height)
        }
        min = 
        {
          'x':center.x - decoration.width/2
          'y':center.y - decoration.height/2     
        }
        max = 
        {
          'x':center.x + decoration.width/2
          'y':center.y + decoration.height/2     
        }
        for cluster, range of decoration.clusters
          for i in _.range(_.random(range[0], range[1]))
            @thangs.push {
              'id':@getRandomThang(clusters[cluster])
              'pos':{
                'x':_.random(min.x, max.x)
                'y':_.random(min.y, max.y)
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
