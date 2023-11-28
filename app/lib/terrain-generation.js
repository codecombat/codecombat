const _ = require('lodash')

const clusters = {
  'hero': {
    'thangs': ['Hero Placeholder'],
    'margin': 1
  },
  'rocks': {
    'thangs': ['Rock 1', 'Rock 2', 'Rock 3', 'Rock 4', 'Rock 5', 'Rock Cluster 1', 'Rock Cluster 2', 'Rock Cluster 3'],
    'margin': 1
  },
  'trees': {
    'thangs': ['Tree 1', 'Tree 2', 'Tree 3', 'Tree 4'],
    'margin': 0.5
    },
  'tree_stands': {
    'thangs': ['Tree Stand 1', 'Tree Stand 2', 'Tree Stand 3', 'Tree Stand 4', 'Tree Stand 5', 'Tree Stand 6'],
    'margin': 3
  },
  'shrubs': {
    'thangs': ['Shrub 1', 'Shrub 2', 'Shrub 3'],
    'margin': 0.5
    },
  'houses': {
    'thangs': ['House 1', 'House 2', 'House 3', 'House 4'],
    'margin': 4
    },
  'animals': {
    'thangs': ['Cow', 'Horse'],
    'margin': 1
    },
  'wood': {
    'thangs': ['Firewood 1', 'Firewood 2', 'Firewood 3'],
    'margin': 1
    },
  'farm': {
    'thangs': ['Farm'],
    'margin': 9
    },
  'cave': {
    'thangs': ['Cave'],
    'margin': 5
    },
  'stone': {
    'thangs': ['Gargoyle', 'Rock Cluster 1', 'Rock Cluster 2', 'Rock Cluster 3'],
    'margin': 1
    },
  'torch': {
    'thangs': ['Torch'],
    'margin': 0
  },
  'chains': {
    'thangs': ['Chains'],
    'margin': 0
  },
  'barrel': {
    'thangs': ['Barrel'],
    'margin': 1
  },
  'doors': {
    'thangs': ['Dungeon Door'],
    'margin': -1
    },
  'grass_floor': {
    'thangs': ['Grass01', 'Grass02', 'Grass03', 'Grass04', 'Grass05'],
    'margin': -1
    },
  'dungeon_wall': {
    'thangs': ['Dungeon Wall'],
    'margin': 2
    },
  'dungeon_floor': {
    'thangs': ['Dungeon Floor'],
    'margin': -1
    },
  'indoor_wall': {
    'thangs': ['Indoor Wall'],
    'margin': 2
    },
  'indoor_floor': {
    'thangs': ['Indoor Floor'],
    'margin': -1
    },
  'furniture': {
    'thangs': ['Bookshelf', 'Chair', 'Table', 'Candle', 'Treasure Chest'],
    'margin': -1
    },
  'desert_walls': {
    'thangs': ['Desert Wall 1', 'Desert Wall 2', 'Desert Wall 3', 'Desert Wall 4', 'Desert Wall 5', 'Desert Wall 6', 'Desert Wall 7', 'Desert Wall 8'],
    'margin': 6
  },
  'desert_floor': {
    'thangs': ['Sand 01', 'Sand 02', 'Sand 03', 'Sand 04', 'Sand 05', 'Sand 06'],
    'margin': -1
  },
  'oases': {
    'thangs': ['Oasis 1', 'Oasis 2', 'Oasis 3'],
    'margin': 4
  },
  'mountain_floor': {
    'thangs': ['Talus 1', 'Talus 2', 'Talus 3', 'Talus 4', 'Talus 5', 'Talus 6'],
    'margin': -1
  },
  'mountain_walls': {
    'thangs': ['Mountain 1','Mountain 3'],
    'margin': 6
  },
  'glacier_floor': {
    'thangs': ['Firn 1', 'Firn 2', 'Firn 3', 'Firn 4', 'Firn 5', 'Firn 6'],
    'margin': -1
  },
  'glacier_walls': {
    'thangs': ['Ice Wall'],
    'margin': 2
  }
}

const presets = {
  'dungeon': {
    'terrainName': 'Dungeon',
    'type':'dungeon',
    'borders':'dungeon_wall',
    'borderNoise':0,
    'borderSize':4,
    'borderThickness':1,
    'floors':'dungeon_floor',
    'decorations': {
      'room': {
        'num': [1,1],
        'width': [12, 20],
        'height': [8, 16],
        'thickness': [2,2],
        'cluster': 'dungeon_wall'
      },
      'hero': {
        'num': [1, 1],
        'width': 2,
        'height': 2,
        'clusters': {
          'hero': [1, 1]
        }
      },
      'barrels': {
        'num': [1,1],
        'width': [8, 12],
        'height': [8, 12],
        'numBarrels': [4,6],
        'cluster': 'barrel'
      },
      'cave': {
        'num':[1,1],
        'width': 10,
        'height': 10,
        'clusters': {
          'cave':[1,1],
          'stone':[2,4]
        }
      }
    }
  },
  'indoor': {
    'terrainName': 'Indoor',
    'type':'indoor',
    'borders':'indoor_wall',
    'borderNoise':0,
    'borderSize':4,
    'borderThickness':1,
    'floors':'indoor_floor',
    'decorations': {
      'room': {
        'num': [1,1],
        'width': [12, 20],
        'height': [8, 16],
        'thickness': [2,2],
        'cluster': 'indoor_wall'
      },
      'hero': {
        'num': [1, 1],
        'width': 2,
        'height': 2,
        'clusters': {
          'hero': [1, 1]
        }
      },
      'furniture': {
        'num':[1,2],
        'width': 15,
        'height': 15,
        'clusters': {
          'furniture':[2,4]
        }
      }
    }
  },
  'grassy': {
    'terrainName': 'Grass',
    'type':'grassy',
    'borders':'tree_stands',
    'borderNoise':1,
    'borderSize':2,
    'borderThickness':2,
    'floors':'grass_floor',
    'decorations': {
      'hero': {
        'num': [1, 1],
        'width': 2,
        'height': 2,
        'clusters': {
          'hero': [1, 1]
        }
      },
      'house': {
        'num':[1,2], //min-max
        'width': 15,
        'height': 15,
        'clusters': {
          'houses':[1,1],
          'trees':[1,2],
          'shrubs':[0,3],
          'rocks':[1,2]
        }
      },
      'farm': {
        'num':[1,1], //min-max
        'width': 25,
        'height': 15,
        'clusters': {
          'farm':[1,1],
          'shrubs':[2,3],
          'wood':[2,4],
          'animals':[2,3]
        }
      }
    }
  },
  'desert': {
    'terrainName': 'Desert',
    'type':'desert',
    'borders':'desert_walls',
    'borderNoise':2,
    'borderSize':4,
    'borderThickness':4,
    'floors':'desert_floor',
    'decorations': {
      'hero': {
        'num': [1, 1],
        'width': 2,
        'height': 2,
        'clusters': {
          'hero': [1, 1]
        }
      },
      'oasis': {
        'num':[1,2], //min-max
        'width': 10,
        'height': 10,
        'clusters': {
          'oases':[1,1],
          'shrubs':[0,5],
          'rocks':[0,2]
        }
      }
    }
  },
  'mountain': {
    'terrainName': 'Mountain',
    'type': 'mountain',
    'floors': 'mountain_floor',
    'borders': 'mountain_walls',
    'borderNoise': 1,
    'borderSize': 1,
    'borderThickness': 1,
    'decorations': {
      'hero': {
        'num': [1, 1],
        'width': 2,
        'height': 2,
        'clusters': {
          'hero': [1, 1]
        }
      }
    }
  },
  'glacier': {
    'terrainName': 'Glacier',
    'type': 'glacier',
    'floors': 'glacier_floor',
    'borders': 'glacier_walls',
    'borderNoise': 0,
    'borderSize': 4,
    'borderThickness': 1,
    'decorations': {
      'hero': {
        'num': [1, 1],
        'width': 2,
        'height': 2,
        'clusters': {
          'hero': [1, 1]
        }
      },
      'room': {
        'num': [1,1],
        'width': [12, 20],
        'height': [8, 16],
        'thickness': [2,2],
        'cluster': 'glacier_walls'
      }
    }
  }
}

const presetSizes = {
  'small': {
    'x':80,
    'y':68,
    'sizeFactor':1
  },
  'large': {
    'x':160,
    'y':136,
    'sizeFactor':2
  }
}

const thangSizes = {
  'floorSize': {
    'x':20,
    'y':17
  },
  'borderSize': {
    'x':4,
    'y':4
  }
}

function generateThangs({ presetName, presetSize, goals }) {
  presetName = (presetName || 'dungeon').toLowerCase()
  presetName = {
    grass: 'grassy',
    volcano: 'glacier'
  }[presetName] || presetName
  const preset = presets[presetName]
  presetSize = presetSizes[presetSize || 'small'] 
  const result = { thangs: [], rects: [], falseCount: 0, preset, presetSize }
  generateFloor(result)
  generateBorder(result)
  generateDecorations(result)
  if (!goals) {
    return result.thangs
  }
  const killThangsGoal = _.find(goals, (goal) => goal.killThangs)
  if (killThangsGoal) {
    generateEnemies(result, killThangsGoal)
  }
  const getToLocationsGoal = _.find(goals, (goal) => goal.getToLocations)
  if (getToLocationsGoal) {
    generateGetToLocations(result, getToLocationsGoal)
  }
  const collectThangsGoal = _.find(goals, (goal) => goal.collectThangs)
  if (collectThangsGoal) {
    generateCollectThangs(result, collectThangsGoal)
  }
  const defendThangsGoal = _.find(goals, (goal) => goal.id === 'humans-survive')
  if (defendThangsGoal) {
    generateDefendThangs(result, defendThangsGoal)
  }
  return result.thangs
}

function generateFloor(result) {
  _.range(0, result.presetSize.x, thangSizes.floorSize.x).forEach(i => {
    _.range(0, result.presetSize.y, thangSizes.floorSize.y).forEach(j => {
      result.thangs.push({
        'id': getRandomThang(clusters[result.preset.floors].thangs),
        'pos': {
          'x': i + (thangSizes.floorSize.x / 2),
          'y': j + (thangSizes.floorSize.y / 2)
        },
        'margin': clusters[result.preset.floors].margin
      })
    })
  })
}

function generateBorder(result) {
  let i, j
  let noiseFactor = result.preset.borderNoise
  if (noiseFactor === undefined) {
    noiseFactor = 1
  }
  for (const i of _.range(0, result.presetSize.x, thangSizes.borderSize.x)) {
    for (const j of _.range(result.preset.borderThickness)) {
      // Bottom wall
      while (!addThang(result, {
        'id': getRandomThang(clusters[result.preset.borders].thangs),
        'pos': {
          'x': i + (result.preset.borderSize/2) + (noiseFactor * _.random(-thangSizes.borderSize.x/2, thangSizes.borderSize.x/2)),
          'y': 0 + (result.preset.borderSize/2) + (noiseFactor * _.random(-thangSizes.borderSize.y/2, thangSizes.borderSize.y))
        },
        'margin': clusters[result.preset.borders].margin
      })) {
        continue
      }

      // Top wall
      while (!addThang(result, {
        'id': getRandomThang(clusters[result.preset.borders].thangs),
        'pos': {
          'x': i + (result.preset.borderSize/2) + (noiseFactor * _.random(-thangSizes.borderSize.x/2, thangSizes.borderSize.x/2)),
          'y': (result.presetSize.y - (result.preset.borderSize/2)) + (noiseFactor * _.random(-thangSizes.borderSize.y, thangSizes.borderSize.y/2))
        },
        'margin': clusters[result.preset.borders].margin
      })) {
        continue
      }

      // Double wall on top
      if (result.preset.type === 'dungeon') {
        addThang(result, {
          'id': getRandomThang(clusters[result.preset.borders].thangs),
          'pos': {
            'x': i + (result.preset.borderSize/2),
            'y': result.presetSize.y - ((3 * result.preset.borderSize)/2)
          },
          'margin': clusters[result.preset.borders].margin
        })
        if ((( i / result.preset.borderSize ) % 2) && (i !== (result.presetSize.x - thangSizes.borderSize.x))) {
          addThang(result, {
            'id': getRandomThang(clusters['torch'].thangs),
            'pos': {
              'x': i + result.preset.borderSize,
              'y': result.presetSize.y - (result.preset.borderSize / 2)
            },
            'margin': clusters['torch'].margin
          })
        } else if (((( i / result.preset.borderSize ) % 2) === 0) && i && (_.random(100) < 30)) {
          addThang(result, {
            'id': getRandomThang(clusters['chains'].thangs),
            'pos': {
              'x': i + result.preset.borderSize,
              'y': result.presetSize.y - (result.preset.borderSize / 2)
            },
            'margin': clusters['chains'].margin
          })
        }
      }
    }
  }

  for (let i of _.range(0, result.presetSize.y, thangSizes.borderSize.y)) {
    for (let j of _.range(result.preset.borderThickness)) {
      // Left wall
      while (!addThang(result, {
        'id': getRandomThang(clusters[result.preset.borders].thangs),
        'pos': {
          'x': 0 + (result.preset.borderSize / 2) + (noiseFactor * _.random(-thangSizes.borderSize.x / 2, thangSizes.borderSize.x)),
          'y': i + (result.preset.borderSize / 2) + (noiseFactor * _.random(-thangSizes.borderSize.y / 2, thangSizes.borderSize.y / 2))
        },
        'margin': clusters[result.preset.borders].margin
      })) {
        continue
      }

      // Right wall
      while (!addThang(result, {
        'id': getRandomThang(clusters[result.preset.borders].thangs),
        'pos': {
          'x': (result.presetSize.x - (result.preset.borderSize / 2)) + (noiseFactor * _.random(-thangSizes.borderSize.x, thangSizes.borderSize.x / 2)),
          'y': i + (result.preset.borderSize / 2) + (noiseFactor * _.random(-thangSizes.borderSize.y / 2, thangSizes.borderSize.y / 2))
        },
        'margin': clusters[result.preset.borders].margin
      })) {
        continue
      }
    }
  }
}

function generateDecorations(result) {
  for (const name in result.preset.decorations) {
    const decoration = result.preset.decorations[name]
    for (const num of _.range(result.presetSize.sizeFactor * _.random(decoration.num[0], decoration.num[1]))) {
      let rect
      if (buildFunctions[name] !== undefined) {
        buildFunctions[name](result, decoration)
        continue
      }

      while (true) {
        rect = {
          'x': _.random((decoration.width / 2) + (result.preset.borderSize / 2) + thangSizes.borderSize.x, result.presetSize.x - (decoration.width / 2) - (result.preset.borderSize / 2) - thangSizes.borderSize.x),
          'y': _.random((decoration.height / 2) + (result.preset.borderSize / 2) + thangSizes.borderSize.y, result.presetSize.y - (decoration.height / 2) - (result.preset.borderSize / 2) - thangSizes.borderSize.y),
          'width': decoration.width,
          'height': decoration.height
        }
        if (addRect(result, rect)) break
      }

      for (const cluster in decoration.clusters) {
        const range = decoration.clusters[cluster]
        for (const i of _.range(_.random(range[0], range[1]))) {
          while (!addThang(result, {
            'id': getRandomThang(clusters[cluster].thangs),
            'pos': {
              'x': _.random(rect.x - (rect.width / 2), rect.x + (rect.width / 2)),
              'y': _.random(rect.y - (rect.height / 2), rect.y + (rect.height / 2))
            },
            'margin': clusters[cluster].margin
          })) {
            continue
          }
        }
      }
    }
  }
}

function generateEnemies(result, killThangsGoal) {
  console.log('generate enemies', killThangsGoal)
  for (let i = 0; i < Math.floor(Math.random() * 8); ) {
    const enemy = {
      'id': getRandomThang(['Ogre Munchkin M', 'Ogre Munchkin F']),
      'pos': {
        'x': _.random(result.presetSize.x / 2, result.presetSize.x - (result.preset.borderSize / 2)),
        'y': _.random(result.presetSize.y / 2, result.presetSize.y - (result.preset.borderSize / 2))
      },
      'margin': 1
    }
    if (addThang(result, enemy)) {
      ++i
    }
    // if (addThang(result, enemy)) {
    //   killThangsGoal.thangIDs.push(enemy.id)
    //   ++i
    // }
  }
}

function generateGetToLocations(result, getToLocationsGoal) {
  console.log('generate get to locations thangs', getToLocationsGoal)
  while (true) {
    const locationThang = {
      'id': 'Goal Trigger',
      'pos': {
        'x': _.random(result.presetSize.x / 2, result.presetSize.x - (result.preset.borderSize / 2)),
        'y': _.random(result.presetSize.y / 2, result.presetSize.y - (result.preset.borderSize / 2))
      },
      'margin': 2
    }
    if (addThang(result, locationThang)) {
      const visibleXMarkThang = _.cloneDeep(locationThang)
      visibleXMarkThang.id = 'X Mark Red'
      result.thangs.push(visibleXMarkThang)
      break
    }
  }
}

function generateCollectThangs(result, collectThangsGoal) {
  console.log('generate collect thangs', collectThangsGoal)
  for (let i = 0; i < Math.floor(Math.random() * 8); ) {
    const collectThang = {
      'id': getRandomThang(['Gem', 'Gem Pile Small', 'Gem Pile Medium', 'Chest of Gems']),
      'pos': {
        'x': _.random(result.presetSize.x / 2, result.presetSize.x - (result.preset.borderSize / 2)),
        'y': _.random(result.presetSize.y / 2, result.presetSize.y - (result.preset.borderSize / 2))
      },
      'margin': 1
    }
    if (addThang(result, collectThang)) {
      ++i
    }
    // if (addThang(result, collectThang)) {
    //   collectThangsGoal.thangIDs.push(collectThang.id)
    //   ++i
    // }
  }
}

function generateDefendThangs(result, defendThangsGoal) {
  console.log('generate defend thangs', defendThangsGoal)
  for (let i = 0; i < Math.floor(Math.random() * 8); ) {
    const defendThang = {
      'id': getRandomThang(['Soldier M', 'Soldier F', 'Archer M', 'Archer F', 'Peasant M', 'Peasant F']),
      'pos': {
        'x': _.random(result.presetSize.x / 2, result.presetSize.x - (result.preset.borderSize / 2)),
        'y': _.random(result.presetSize.y / 2, result.presetSize.y - (result.preset.borderSize / 2))
      },
      'margin': 1
    }
    if (addThang(result, defendThang)) {
      ++i
    }
    // if (addThang(result, defendThang)) {
    //   defendThangsGoal.thangIDs.push(defendThang.id)
    //   ++i
    // }
  }
}

const buildFunctions = {}

buildFunctions.room = function(result, room) {
  let rect, roomThickness
  const grid = result.preset.borderSize
  while (true) {
    rect = {
      'width':result.presetSize.sizeFactor * (room.width[0] + (grid * _.random(0, (room.width[1] - room.width[0])/grid))),
      'height':result.presetSize.sizeFactor * (room.height[0] + (grid * _.random(0, (room.height[1] - room.height[0])/grid)))
    }
    // This logic isn't quite right--it makes the rooms bigger than intended--but it's snapping correctly, which is fine for now.
    rect.width = (Math.round((rect.width - grid) / (2 * grid)) * 2 * grid) + grid
    rect.height = (Math.round((rect.height - grid) / (2 * grid)) * 2 * grid) + grid
    roomThickness = _.random(room.thickness[0], room.thickness[1])
    rect.x = _.random((rect.width/2) + (grid * (roomThickness+1.5)), result.presetSize.x - (rect.width/2) - (grid * (roomThickness+1.5)))
    rect.y = _.random((rect.height/2) + (grid * (roomThickness+2.5)), result.presetSize.y - (rect.height/2) - (grid * (roomThickness+3.5)))
    // Snap room walls to the wall grid.
    rect.x = Math.round((rect.x - (grid / 2)) / grid) * grid
    rect.y = Math.round((rect.y - (grid / 2)) / grid) * grid
    if (addRect(result, {
      'x': rect.x,
      'y': rect.y,
      'width': rect.width + (2.5 * roomThickness * grid),
      'height': rect.height + (2.5 * roomThickness * grid)
    })) { break }
  }

  const xRange = _.range((rect.x - (rect.width/2)) + grid, rect.x + (rect.width/2), grid)
  const topDoor = _.random(1) > 0.5
  const topDoorX = xRange[_.random(0, xRange.length-1)]
  const bottomDoor = !topDoor ? true : _.random(1) > 0.5
  const bottomDoorX = xRange[_.random(0, xRange.length-1)]

  for (let t of _.range(0, roomThickness + 1)) {
    for (let i of _.range(rect.x - (rect.width / 2) - ((t - 1) * grid), rect.x + (rect.width / 2) + (t * grid), grid)) {
      // Bottom wall
      var thang = {
        'id': getRandomThang(clusters[room.cluster].thangs),
        'pos': {
          'x': i,
          'y': rect.y - (rect.height/2) - (t * grid)
        },
        'margin': clusters[room.cluster].margin
      }
      if ((i === bottomDoorX) && bottomDoor) {
        thang.id = getRandomThang(clusters['doors'].thangs)
        thang.pos.y -= grid/3
      }
      if ((i !== bottomDoorX) || (t === roomThickness) || !bottomDoor) { addThang(result, thang) }

      if ((t === roomThickness) && (i !== (rect.x - (rect.width/2) - ((t-1) * grid))) && (result.preset.type === 'dungeon')) {
        if (( (i !== bottomDoorX) && (i !== (bottomDoorX + grid)) ) || !bottomDoor) {
          addThang(result, {
            'id': getRandomThang(clusters['torch'].thangs),
            'pos': {
              'x': thang.pos.x - (grid / 2),
              'y': thang.pos.y + grid
            },
            'margin': clusters['torch'].margin
          })
        }
      }

      // Top wall
      thang = {
        'id': getRandomThang(clusters[room.cluster].thangs),
        'pos': {
          'x': i,
          'y': rect.y + (rect.height/2) + (t * grid)
        },
        'margin': clusters[room.cluster].margin
      }
      if ((i === topDoorX) && topDoor) {
        thang.id = getRandomThang(clusters['doors'].thangs)
        thang.pos.y -= grid
      }
      if ((i !== topDoorX) || (t === roomThickness) || !topDoor) { addThang(result, thang) }
    }
  }

  for (let t of _.range(0, roomThickness)) {
    for (let i of _.range(rect.y - (rect.height / 2) - (t * grid), rect.y + (rect.height / 2) + ((t + 1) * grid), grid)) {
      // Left wall
      addThang(result, {
        'id': getRandomThang(clusters[room.cluster].thangs),
        'pos': {
          'x': rect.x - (rect.width / 2) - (t * grid),
          'y': i
        },
        'margin': clusters[room.cluster].margin
      })

      // Right wall
      addThang(result, {
        'id': getRandomThang(clusters[room.cluster].thangs),
        'pos': {
          'x': rect.x + (rect.width / 2) + (t * grid),
          'y': i
        },
        'margin': clusters[room.cluster].margin
      })
    }
  }
}

buildFunctions.barrels = function(result, decoration) {
  let rect = {
    'width': result.presetSize.sizeFactor * _.random(decoration.width[0], decoration.width[1]),
    'height': result.presetSize.sizeFactor * _.random(decoration.height[0], decoration.height[1])
  }
  const x = [(rect.width / 2) + result.preset.borderSize, result.presetSize.x - (rect.width / 2) - result.preset.borderSize]
  const y = [(rect.height / 2) + result.preset.borderSize, result.presetSize.y - (rect.height / 2) - (2 * result.preset.borderSize)]

  x.forEach(i => {
    y.forEach(j => {
      if (_.random(100) < 40) {
        rect = {
          'x': i,
          'y': j,
          'width': rect.width,
          'height': rect.height
        }
        if (addRect(result, rect)) {
          _.range(_.random(decoration.numBarrels[0], decoration.numBarrels[1])).forEach(num => {
            while (!addThang(result, {
              'id': getRandomThang(clusters[decoration.cluster].thangs),
              'pos': {
                'x': _.random(rect.x - (rect.width / 2), rect.x + (rect.width / 2)),
                'y': _.random(rect.y - (rect.height / 2), rect.y + (rect.height / 2))
              },
              'margin': clusters[decoration.cluster].margin
            })) {
              continue
            }
          })
        }
      }
    })
  })
}

function addThang(result, thang) {
  if (result.falseCount > 100) {
    // console.log('infinite loop', thang)
    result.falseCount = 0
    return true
  }

  for (const existingThang of result.thangs) {
    if ((existingThang.margin === -1) || (thang.margin === -1)) {
      continue
    }
    if ((Math.abs(existingThang.pos.x - thang.pos.x) < (thang.margin + existingThang.margin)) && (Math.abs(existingThang.pos.y - thang.pos.y) < (thang.margin + existingThang.margin))) {
      result.falseCount++
      return false
    }
  }

  result.thangs.push(thang)
  return true
}

function addRect(result, rect) {
  if (result.falseCount > 100) {
    // console.log('infinite loop', rect)
    result.falseCount = 0
    return true
  }

  for (const existingRect of result.rects) {
    if ((Math.abs(existingRect.x - rect.x) <= ((rect.width / 2) + (existingRect.width / 2))) && (Math.abs(existingRect.y - rect.y) <= ((rect.height / 2) + (existingRect.height / 2)))) {
      result.falseCount++
      return false
    }
  }

  result.rects.push(rect)
  return true
}

function getRandomThang(thangList) {
  return thangList[_.random(0, thangList.length-1)]
}

module.exports = {
  presets,
  presetSizes,
  generateThangs
}
