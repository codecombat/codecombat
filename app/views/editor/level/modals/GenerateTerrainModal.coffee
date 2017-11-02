require('app/styles/editor/level/modal/generate-terrain-modal.sass')
ModalView = require 'views/core/ModalView'
template = require 'templates/editor/level/modal/generate-terrain-modal'
CocoModel = require 'models/CocoModel'

clusters = {
  'hero': {
    'thangs': ['Hero Placeholder']
    'margin': 1
  }
  'rocks': {
    'thangs': ['Rock 1', 'Rock 2', 'Rock 3', 'Rock 4', 'Rock 5', 'Rock Cluster 1', 'Rock Cluster 2', 'Rock Cluster 3']
    'margin': 1
  }
  'trees': {
    'thangs': ['Tree 1', 'Tree 2', 'Tree 3', 'Tree 4']
    'margin': 0.5
    }
  'tree_stands': {
    'thangs': ['Tree Stand 1', 'Tree Stand 2', 'Tree Stand 3', 'Tree Stand 4', 'Tree Stand 5', 'Tree Stand 6']
    'margin': 3
  }
  'shrubs': {
    'thangs': ['Shrub 1', 'Shrub 2', 'Shrub 3']
    'margin': 0.5
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
  'desert_walls': {
    'thangs': ['Desert Wall 1', 'Desert Wall 2', 'Desert Wall 3', 'Desert Wall 4', 'Desert Wall 5', 'Desert Wall 6', 'Desert Wall 7', 'Desert Wall 8']
    'margin': 6
  }
  'desert_floor': {
    'thangs': ['Sand 01', 'Sand 02', 'Sand 03', 'Sand 04', 'Sand 05', 'Sand 06']
    'margin': -1
  }
  'oases': {
    'thangs': ['Oasis 1', 'Oasis 2', 'Oasis 3']
    'margin': 4
  }
  'mountain_floor': {
    'thangs': ['Talus 1', 'Talus 2', 'Talus 3', 'Talus 4', 'Talus 5', 'Talus 6']
    'margin': -1
  }
  'mountain_walls': {
    'thangs': ['Mountain 1','Mountain 3']
    'margin': 6
  }
  'glacier_floor': {
    'thangs': ['Firn 1', 'Firn 2', 'Firn 3', 'Firn 4', 'Firn 5', 'Firn 6']
    'margin': -1
  }
  'glacier_walls': {
    'thangs': ['Ice Wall']
    'margin': 2
  }
}

presets = {
  'dungeon': {
    'terrainName': 'Dungeon'
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
      'hero': {
        'num': [1, 1]
        'width': 2
        'height': 2
        'clusters': {
          'hero': [1, 1]
        }
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
    'terrainName': 'Indoor'
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
      'hero': {
        'num': [1, 1]
        'width': 2
        'height': 2
        'clusters': {
          'hero': [1, 1]
        }
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
    'terrainName': 'Grass'
    'type':'grassy'
    'borders':'tree_stands'
    'borderNoise':1
    'borderSize':2
    'borderThickness':2
    'floors':'grass_floor'
    'decorations': {
      'hero': {
        'num': [1, 1]
        'width': 2
        'height': 2
        'clusters': {
          'hero': [1, 1]
        }
      }
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
  'desert': {
    'terrainName': 'Desert'
    'type':'desert'
    'borders':'desert_walls'
    'borderNoise':2
    'borderSize':4
    'borderThickness':4
    'floors':'desert_floor'
    'decorations': {
      'hero': {
        'num': [1, 1]
        'width': 2
        'height': 2
        'clusters': {
          'hero': [1, 1]
        }
      }
      'oasis': {
        'num':[1,2] #min-max
        'width': 10
        'height': 10
        'clusters': {
          'oases':[1,1]
          'shrubs':[0,5]
          'rocks':[0,2]
        }
      }
    }
  },
  'mountain': {
    'terrainName': 'Mountain'
    'type': 'mountain'
    'floors': 'mountain_floor'
    'borders': 'mountain_walls'
    'borderNoise': 1
    'borderSize': 1
    'borderThickness': 1
    'decorations': {
      'hero': {
        'num': [1, 1]
        'width': 2
        'height': 2
        'clusters': {
          'hero': [1, 1]
        }
      }
    }
  },
  'glacier': {
    'terrainName': 'Glacier'
    'type': 'glacier'
    'floors': 'glacier_floor'
    'borders': 'glacier_walls'
    'borderNoise': 0
    'borderSize': 4
    'borderThickness': 1
    'decorations': {
      'hero': {
        'num': [1, 1]
        'width': 2
        'height': 2
        'clusters': {
          'hero': [1, 1]
        }
      }
      'Room': {
        'num': [1,1]
        'width': [12, 20]
        'height': [8, 16]
        'thickness': [2,2]
        'cluster': 'glacier_walls'
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
  }}


module.exports = class GenerateTerrainModal extends ModalView
  id: 'generate-terrain-modal'
  template: template
  plain: true
  modalWidthPercent: 90

  events:
    'click .choose-option': 'onGenerate'

  constructor: (options) ->
    super options
    @presets = presets
    @presetSizes = presetSizes

  onRevertModel: (e) ->
    id = $(e.target).val()
    CocoModel.backedUp[id].revert()
    $(e.target).closest('tr').remove()
    @reloadOnClose = true

  onGenerate: (e) ->
    target = $(e.target)
    presetType = target.attr 'data-preset-type'
    presetSize = target.attr 'data-preset-size'
    @generateThangs presetType, presetSize
    Backbone.Mediator.publish 'editor:random-terrain-generated', thangs: @thangs, terrain: presets[presetType].terrainName
    @hide()

  generateThangs: (presetName, presetSize) ->
    @falseCount = 0
    preset = presets[presetName]
    presetSize = presetSizes[presetSize]
    @thangs = []
    @rects = []
    @generateFloor preset, presetSize
    @generateBorder preset, presetSize, preset.borderNoise
    @generateDecorations preset, presetSize

  generateFloor: (preset, presetSize) ->
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

  generateBorder: (preset, presetSize, noiseFactor=1) ->
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
                'y': presetSize.y - preset.borderSize / 2
              }
              'margin': clusters['torch'].margin
            }
          else if ( i / preset.borderSize ) % 2 is 0 and i and _.random(100) < 30
            @addThang {
              'id': @getRandomThang(clusters['chains'].thangs)
              'pos': {
                'x': i + preset.borderSize
                'y': presetSize.y - preset.borderSize / 2
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

  generateDecorations: (preset, presetSize)->
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
    grid = preset.borderSize
    while true
      rect = {
        'width':presetSize.sizeFactor * (room.width[0] + grid * _.random(0, (room.width[1] - room.width[0])/grid))
        'height':presetSize.sizeFactor * (room.height[0] + grid * _.random(0, (room.height[1] - room.height[0])/grid))
      }
      # This logic isn't quite right--it makes the rooms bigger than intended--but it's snapping correctly, which is fine for now.
      rect.width = Math.round((rect.width - grid) / (2 * grid)) * 2 * grid + grid
      rect.height = Math.round((rect.height - grid) / (2 * grid)) * 2 * grid + grid
      roomThickness = _.random(room.thickness[0], room.thickness[1])
      rect.x = _.random(rect.width/2 + grid * (roomThickness+1.5), presetSize.x - rect.width/2 - grid * (roomThickness+1.5))
      rect.y = _.random(rect.height/2 + grid * (roomThickness+2.5), presetSize.y - rect.height/2 - grid * (roomThickness+3.5))
      # Snap room walls to the wall grid.
      rect.x = Math.round((rect.x - grid / 2) / grid) * grid
      rect.y = Math.round((rect.y - grid / 2) / grid) * grid
      break if @addRect {
        'x': rect.x
        'y': rect.y
        'width': rect.width + 2.5 * roomThickness * grid
        'height': rect.height + 2.5 * roomThickness * grid
      }

    xRange = _.range(rect.x - rect.width/2 + grid, rect.x + rect.width/2, grid)
    topDoor = _.random(1) > 0.5
    topDoorX = xRange[_.random(0, xRange.length-1)]
    bottomDoor = if not topDoor then true else _.random(1) > 0.5
    bottomDoorX = xRange[_.random(0, xRange.length-1)]

    for t in _.range(0, roomThickness+1)
      for i in _.range(rect.x - rect.width/2 - (t-1) * grid, rect.x + rect.width/2 + t * grid, grid)
        # Bottom wall
        thang = {
          'id': @getRandomThang(clusters[room.cluster].thangs)
          'pos': {
            'x': i
            'y': rect.y - rect.height/2 - t * grid
          }
          'margin': clusters[room.cluster].margin
        }
        if i is bottomDoorX and bottomDoor
          thang.id = @getRandomThang(clusters['doors'].thangs)
          thang.pos.y -= grid/3
        @addThang thang unless i is bottomDoorX and t isnt roomThickness and bottomDoor

        if t is roomThickness and i isnt rect.x - rect.width/2 - (t-1) * grid and preset.type is 'dungeon'
          if ( i isnt bottomDoorX and i isnt bottomDoorX + grid ) or not bottomDoor
            @addThang {
              'id': @getRandomThang(clusters['torch'].thangs)
              'pos': {
                'x': thang.pos.x - grid / 2
                'y': thang.pos.y + grid
              }
              'margin': clusters['torch'].margin
            }

        # Top wall
        thang = {
          'id': @getRandomThang(clusters[room.cluster].thangs)
          'pos': {
            'x': i
            'y': rect.y + rect.height/2 + t * grid
          }
          'margin': clusters[room.cluster].margin
        }
        if i is topDoorX and topDoor
          thang.id = @getRandomThang(clusters['doors'].thangs)
          thang.pos.y -= grid
        @addThang thang unless i is topDoorX and t isnt roomThickness and topDoor

    for t in _.range(0, roomThickness)
      for i in _.range(rect.y - rect.height/2 - t * grid, rect.y + rect.height/2 + (t+1) * grid, grid)
        # Left wall
        @addThang {
          'id': @getRandomThang(clusters[room.cluster].thangs)
          'pos': {
            'x': rect.x - rect.width/2 - t * grid
            'y': i
          }
          'margin': clusters[room.cluster].margin
        }

        # Right wall
        @addThang {
          'id': @getRandomThang(clusters[room.cluster].thangs)
          'pos': {
            'x': rect.x + rect.width/2 + t * grid
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

  onHidden: ->
    location.reload() if @reloadOnClose
