ModalView = require 'views/kinds/ModalView'
template = require 'templates/editor/level/modal/terrain_randomize'
CocoModel = require 'models/CocoModel'

clusters = {
  'rocks': {
    'thangs': ['Rock 1', 'Rock 2', 'Rock 3', 'Rock 4', 'Rock 5', 'Rock Cluster 1', 'Rock Cluster 2', 'Rock Cluster 3']
    'margin': 1
  }
  'trees': {
    'thangs': ['Tree 1', 'Tree 2', 'Tree 3', 'Tree 4']
    'margin': 0
    }
  'shrubs': {
    'thangs': ['Shrub 1', 'Shrub 2', 'Shrub 3']
    'margin': 0
    }
  'houses': {
    'thangs': ['House 1', 'House 2', 'House 3', 'House 4']
    'margin': 4
    }
  'animals': {
    'thangs': ['Cow', 'Horse']
    'margin': 1
    }
  'wood': {
    'thangs': ['Firewood 1', 'Firewood 2', 'Firewood 3']
    'margin': 1
    }
  'farm': {
    'thangs': ['Farm']
    'margin': 9
    }
  'cave': {
    'thangs': ['Cave']
    'margin': 5
    }
  'stone': {
    'thangs': ['Gargoyle', 'Rock Cluster 1', 'Rock Cluster 2', 'Rock Cluster 3']
    'margin': 1
    }
  'torch': {
    'thangs': ['Torch']
    'margin': 0
  }
  'chains': {
    'thangs': ['Chains']
    'margin': 0
  }
  'barrel': {
    'thangs': ['Barrel']
    'margin': 1
  }
  'doors': {
    'thangs': ['Dungeon Door']
    'margin': -1
    }
  'grass_floor': {
    'thangs': ['Grass01', 'Grass02', 'Grass03', 'Grass04', 'Grass05']
    'margin': -1
    }
  'dungeon_wall': {
    'thangs': ['Dungeon Wall']
    'margin': 2
    }
  'dungeon_floor': {
    'thangs': ['Dungeon Floor']
    'margin': -1
    }
  'indoor_wall': {
    'thangs': ['Indoor Wall']
    'margin': 2
    }
  'indoor_floor': {
    'thangs': ['Indoor Floor']
    'margin': -1
    }
  'furniture': {
    'thangs': ['Bookshelf', 'Chair', 'Table', 'Candle', 'Treasure Chest']
    'margin': -1
    }
}

presets = {
  'dungeon': {
    'type':'dungeon'
    'borders':'dungeon_wall'
    'borderNoise':0
    'borderSize':4
    'borderThickness':1
    'floors':'dungeon_floor'
    'decorations': {
      'Room': {
        'num': [1,1]
        'width': [12, 20]
        'height': [8, 16]
        'thickness': [2,2]
        'cluster': 'dungeon_wall'
      }
      'Barrels': {
        'num': [1,1]
        'width': [8, 12]
        'height': [8, 12]
        'numBarrels': [4,6]
        'cluster': 'barrel' 
      }
      'cave': {
        'num':[1,1]
        'width': 10
        'height': 10
        'clusters': {
          'cave':[1,1]
          'stone':[2,4]
        }
      }
    }
  }
  'indoor': {
    'type':'indoor'
    'borders':'indoor_wall'
    'borderNoise':0
    'borderSize':4
    'borderThickness':1
    'floors':'indoor_floor'
    'decorations': {
      'Room': {
        'num': [1,1]
        'width': [12, 20]
        'height': [8, 16]
        'thickness': [2,2]
        'cluster': 'indoor_wall'
      }
      'furniture': {
        'num':[1,2]
        'width': 15
        'height': 15
        'clusters': {
          'furniture':[2,4]
        }
      }
    }
  }
  'grassy': {
    'type':'grassy'
    'borders':'trees'
    'borderNoise':1
    'borderSize':0
    'borderThickness':3
    'floors':'grass_floor'
    'decorations': {
      'house': {
        'num':[1,2] #min-max
        'width': 15
        'height': 15
        'clusters': {
          'houses':[1,1]
          'trees':[1,2]
          'shrubs':[0,3]
          'rocks':[1,2]
        }
      }
      'farm': {
        'num':[1,1] #min-max
        'width': 25
        'height': 15
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

presetSizes = {
  'small': {
    'x':80
    'y':68
    'sizeFactor':1
  }
  'large': {
    'x':160
    'y':136
    'sizeFactor':2
  }
}

thangSizes = {
  'floorSize': {
    'x':20
    'y':17
  }
  'borderSize': {
    'x':4
    'y':4
  }
}

module.exports = class TerrainRandomizeModal extends ModalView
  id: 'terrain-randomize-modal'
  template: template
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
    @falseCount = 0
    preset = presets[presetName]
    presetSize = presetSizes[presetSize]
    @thangs = []
    @rects = []
    @randomizeFloor preset, presetSize
    @randomizeBorder preset, presetSize, preset.borderNoise
    @randomizeDecorations preset, presetSize

  randomizeFloor: (preset, presetSize) ->
    for i in _.range(0, presetSize.x, thangSizes.floorSize.x)
      for j in _.range(0, presetSize.y, thangSizes.floorSize.y)
        @thangs.push {
          'id': @getRandomThang(clusters[preset.floors].thangs)
          'pos': {
            'x': i + thangSizes.floorSize.x/2
            'y': j + thangSizes.floorSize.y/2
          }
          'margin': clusters[preset.floors].margin
        }

  randomizeBorder: (preset, presetSize, noiseFactor=1) ->
    for i in _.range(0, presetSize.x, thangSizes.borderSize.x)
      for j in _.range(preset.borderThickness)
        # Bottom wall
        while not @addThang {
          'id': @getRandomThang(clusters[preset.borders].thangs)
          'pos': {
            'x': i + preset.borderSize/2 + noiseFactor * _.random(-thangSizes.borderSize.x/2, thangSizes.borderSize.x/2)
            'y': 0 + preset.borderSize/2 + noiseFactor * _.random(-thangSizes.borderSize.y/2, thangSizes.borderSize.y)
          }
          'margin': clusters[preset.borders].margin
        }
          continue

        # Top wall
        while not @addThang {
          'id': @getRandomThang(clusters[preset.borders].thangs)
          'pos': {
            'x': i + preset.borderSize/2 + noiseFactor * _.random(-thangSizes.borderSize.x/2, thangSizes.borderSize.x/2)
            'y': presetSize.y - preset.borderSize/2 + noiseFactor * _.random(-thangSizes.borderSize.y, thangSizes.borderSize.y/2)
          }
          'margin': clusters[preset.borders].margin
        }
          continue

        # Double wall on top
        if preset.type is 'dungeon'
          @addThang {
            'id': @getRandomThang(clusters[preset.borders].thangs)
            'pos': {
              'x': i + preset.borderSize/2 
              'y': presetSize.y - 3 * preset.borderSize/2
            }
            'margin': clusters[preset.borders].margin
          } 
          if ( i / preset.borderSize ) % 2 and i isnt presetSize.x - thangSizes.borderSize.x
            @addThang {
              'id': @getRandomThang(clusters['torch'].thangs)
              'pos': {
                'x': i + preset.borderSize 
                'y': presetSize.y - preset.borderSize
              }
              'margin': clusters['torch'].margin
            } 
          else if ( i / preset.borderSize ) % 2 is 0 and i and _.random(100) < 30
            @addThang {
              'id': @getRandomThang(clusters['chains'].thangs)
              'pos': {
                'x': i + preset.borderSize 
                'y': presetSize.y - preset.borderSize
              }
              'margin': clusters['chains'].margin
            } 

    for i in _.range(0, presetSize.y, thangSizes.borderSize.y)
      for j in _.range(preset.borderThickness)
        # Left wall
        while not @addThang {
          'id': @getRandomThang(clusters[preset.borders].thangs)
          'pos': {
            'x': 0 + preset.borderSize/2 + noiseFactor * _.random(-thangSizes.borderSize.x/2, thangSizes.borderSize.x)
            'y': i + preset.borderSize/2 + noiseFactor * _.random(-thangSizes.borderSize.y/2, thangSizes.borderSize.y/2)
          }
          'margin': clusters[preset.borders].margin
        }
          continue

        # Right wall
        while not @addThang {
          'id': @getRandomThang(clusters[preset.borders].thangs)
          'pos': {
            'x': presetSize.x - preset.borderSize/2 + noiseFactor * _.random(-thangSizes.borderSize.x, thangSizes.borderSize.x/2)
            'y': i + preset.borderSize/2 + noiseFactor * _.random(-thangSizes.borderSize.y/2, thangSizes.borderSize.y/2)
          }
          'margin': clusters[preset.borders].margin
        }
          continue

  randomizeDecorations: (preset, presetSize)->
    for name, decoration of preset.decorations
      for num in _.range(presetSize.sizeFactor * _.random(decoration.num[0], decoration.num[1]))
        if @['build'+name] isnt undefined
          @['build'+name](preset, presetSize, decoration)
          continue
        while true
          rect = {
            'x':_.random(decoration.width/2 + preset.borderSize/2 + thangSizes.borderSize.x, presetSize.x - decoration.width/2 - preset.borderSize/2 - thangSizes.borderSize.x),
            'y':_.random(decoration.height/2 + preset.borderSize/2 + thangSizes.borderSize.y, presetSize.y - decoration.height/2 - preset.borderSize/2 - thangSizes.borderSize.y)
            'width':decoration.width
            'height':decoration.height
          }
          break if @addRect rect

        for cluster, range of decoration.clusters
          for i in _.range(_.random(range[0], range[1]))
            while not @addThang {
              'id':@getRandomThang(clusters[cluster].thangs)
              'pos':{
                'x':_.random(rect.x - rect.width/2, rect.x + rect.width/2)
                'y':_.random(rect.y - rect.height/2, rect.y + rect.height/2)
              }
              'margin':clusters[cluster].margin
            }
              continue

  buildRoom: (preset, presetSize, room) ->
    while true
      rect = {
        'width':presetSize.sizeFactor * (room.width[0] + preset.borderSize * _.random(0, (room.width[1] - room.width[0])/preset.borderSize))
        'height':presetSize.sizeFactor * (room.height[0] + preset.borderSize * _.random(0, (room.height[1] - room.height[0])/preset.borderSize))
      }
      roomThickness = _.random(room.thickness[0], room.thickness[1])
      rect.x = _.random(rect.width/2 + preset.borderSize * (roomThickness+1.5), presetSize.x - rect.width/2 - preset.borderSize * (roomThickness+1.5))
      rect.y = _.random(rect.height/2 + preset.borderSize * (roomThickness+2.5), presetSize.y - rect.height/2 - preset.borderSize * (roomThickness+3.5))
      # Snap room walls to the wall grid.
      rect.x = Math.round((rect.x - preset.borderSize / 2) / preset.borderSize) * preset.borderSize + preset.borderSize / 2
      rect.y = Math.round((rect.y - preset.borderSize / 2) / preset.borderSize) * preset.borderSize + preset.borderSize / 2
      break if @addRect {
        'x': rect.x
        'y': rect.y
        'width': rect.width + 2.5 * roomThickness * preset.borderSize
        'height': rect.height + 2.5 * roomThickness * preset.borderSize
      }

    xRange = _.range(rect.x - rect.width/2 + preset.borderSize, rect.x + rect.width/2, preset.borderSize)
    topDoor = _.random(1) > 0.5
    topDoorX = xRange[_.random(0, xRange.length-1)]
    bottomDoor = if not topDoor then true else _.random(1) > 0.5
    bottomDoorX = xRange[_.random(0, xRange.length-1)]

    for t in _.range(0, roomThickness+1)
      for i in _.range(rect.x - rect.width/2 - (t-1) * preset.borderSize, rect.x + rect.width/2 + t * preset.borderSize, preset.borderSize)
        # Bottom wall
        thang = {
          'id': @getRandomThang(clusters[room.cluster].thangs)
          'pos': {
            'x': i
            'y': rect.y - rect.height/2 - t * preset.borderSize
          }
          'margin': clusters[room.cluster].margin
        }
        if i is bottomDoorX and bottomDoor
          thang.id = @getRandomThang(clusters['doors'].thangs)
          thang.pos.y -= preset.borderSize/3
        @addThang thang unless i is bottomDoorX and t isnt roomThickness and bottomDoor

        if t is roomThickness and i isnt rect.x - rect.width/2 - (t-1) * preset.borderSize and preset.type is 'dungeon'
          if ( i isnt bottomDoorX and i isnt bottomDoorX + preset.borderSize ) or not bottomDoor
            @addThang {
              'id': @getRandomThang(clusters['torch'].thangs)
              'pos': {
                'x': thang.pos.x - preset.borderSize / 2
                'y': thang.pos.y + preset.borderSize / 2
              } 
              'margin': clusters['torch'].margin
            }

        # Top wall
        thang = {
          'id': @getRandomThang(clusters[room.cluster].thangs)
          'pos': {
            'x': i
            'y': rect.y + rect.height/2 + t * preset.borderSize
          }
          'margin': clusters[room.cluster].margin
        }
        if i is topDoorX and topDoor
          thang.id = @getRandomThang(clusters['doors'].thangs)
          thang.pos.y -= preset.borderSize
        @addThang thang unless i is topDoorX and t isnt roomThickness and topDoor

    for t in _.range(0, roomThickness)
      for i in _.range(rect.y - rect.height/2 - t * preset.borderSize, rect.y + rect.height/2 + (t+1) * preset.borderSize, preset.borderSize)
        # Left wall 
        @addThang {
          'id': @getRandomThang(clusters[room.cluster].thangs)
          'pos': {
            'x': rect.x - rect.width/2 - t * preset.borderSize
            'y': i
          }
          'margin': clusters[room.cluster].margin
        }

        # Right wall 
        @addThang {
          'id': @getRandomThang(clusters[room.cluster].thangs)
          'pos': {
            'x': rect.x + rect.width/2 + t * preset.borderSize
            'y': i
          }
          'margin': clusters[room.cluster].margin
        }

  buildBarrels: (preset, presetSize, decoration) ->
    rect = {
      'width':presetSize.sizeFactor * ( _.random( decoration.width[0], decoration.width[1] ) )
      'height':presetSize.sizeFactor * ( _.random( decoration.height[0], decoration.height[1] ) )
    }
    x = [ rect.width/2 + preset.borderSize , presetSize.x - rect.width/2 - preset.borderSize ]
    y = [ rect.height/2 + preset.borderSize , presetSize.y - rect.height/2 - 2 * preset.borderSize ]

    for i in x
      for j in y
        if _.random(100) < 40
          rect = {
            'x': i
            'y': j
            'width': rect.width
            'height': rect.height
          }
          if @addRect rect
            for num in _.range( _.random( decoration.numBarrels[0], decoration.numBarrels[1] ) )
              while not @addThang {
                'id': @getRandomThang(clusters[decoration.cluster].thangs)
                'pos': {
                  'x': _.random(rect.x - rect.width/2, rect.x + rect.width/2)
                  'y': _.random(rect.y - rect.height/2, rect.y + rect.height/2)
                }
                'margin': clusters[decoration.cluster].margin
              }
                continue

  addThang: (thang) ->
    if @falseCount > 100
      console.log 'infinite loop', thang
      @falseCount = 0
      return true
    for existingThang in @thangs
      if existingThang.margin is -1 or thang.margin is -1
        continue
      if Math.abs(existingThang.pos.x - thang.pos.x) < thang.margin + existingThang.margin and Math.abs(existingThang.pos.y - thang.pos.y) < thang.margin + existingThang.margin
        @falseCount++
        return false
    @thangs.push thang
    true

  addRect: (rect) ->
    if @falseCount > 100
      console.log 'infinite loop', rect
      @falseCount = 0
      return true
    for existingRect in @rects
      if Math.abs(existingRect.x - rect.x) <= rect.width/2 + existingRect.width/2 and Math.abs(existingRect.y - rect.y) <= rect.height/2 + existingRect.height/2
        @falseCount++
        return false
    @rects.push rect
    true

  getRandomThang: (thangList) ->
    return thangList[_.random(0, thangList.length-1)]

  getRenderData: ->
    c = super()
    c.presets = presets
    c.presetSizes = presetSizes
    c

  onHidden: ->
    location.reload() if @reloadOnClose
