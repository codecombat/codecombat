// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let GenerateTerrainModal;
require('app/styles/editor/level/modal/generate-terrain-modal.sass');
const ModalView = require('views/core/ModalView');
const template = require('app/templates/editor/level/modal/generate-terrain-modal');
const CocoModel = require('models/CocoModel');

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
};

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
      'Room': {
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
      'Barrels': {
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
      'Room': {
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
      'Room': {
        'num': [1,1],
        'width': [12, 20],
        'height': [8, 16],
        'thickness': [2,2],
        'cluster': 'glacier_walls'
      }
    }
  }
};

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
};

const thangSizes = {
  'floorSize': {
    'x':20,
    'y':17
  },
  'borderSize': {
    'x':4,
    'y':4
  }};


module.exports = (GenerateTerrainModal = (function() {
  GenerateTerrainModal = class GenerateTerrainModal extends ModalView {
    static initClass() {
      this.prototype.id = 'generate-terrain-modal';
      this.prototype.template = template;
      this.prototype.plain = true;
      this.prototype.modalWidthPercent = 90;
  
      this.prototype.events =
        {'click .choose-option': 'onGenerate'};
    }

    constructor(options) {
      super(options);
      this.presets = presets;
      this.presetSizes = presetSizes;
    }

    onRevertModel(e) {
      const id = $(e.target).val();
      CocoModel.backedUp[id].revert();
      $(e.target).closest('tr').remove();
      return this.reloadOnClose = true;
    }

    onGenerate(e) {
      const target = $(e.target);
      const presetType = target.attr('data-preset-type');
      const presetSize = target.attr('data-preset-size');
      this.generateThangs(presetType, presetSize);
      Backbone.Mediator.publish('editor:random-terrain-generated', {thangs: this.thangs, terrain: presets[presetType].terrainName});
      return this.hide();
    }

    generateThangs(presetName, presetSize) {
      this.falseCount = 0;
      const preset = presets[presetName];
      presetSize = presetSizes[presetSize];
      this.thangs = [];
      this.rects = [];
      this.generateFloor(preset, presetSize);
      this.generateBorder(preset, presetSize, preset.borderNoise);
      return this.generateDecorations(preset, presetSize);
    }

    generateFloor(preset, presetSize) {
      return Array.from(_.range(0, presetSize.x, thangSizes.floorSize.x)).map((i) =>
        Array.from(_.range(0, presetSize.y, thangSizes.floorSize.y)).map((j) =>
          this.thangs.push({
            'id': this.getRandomThang(clusters[preset.floors].thangs),
            'pos': {
              'x': i + (thangSizes.floorSize.x/2),
              'y': j + (thangSizes.floorSize.y/2)
            },
            'margin': clusters[preset.floors].margin
          })));
    }

    generateBorder(preset, presetSize, noiseFactor) {
      let i, j;
      if (noiseFactor == null) { noiseFactor = 1; }
      for (i of Array.from(_.range(0, presetSize.x, thangSizes.borderSize.x))) {
        for (j of Array.from(_.range(preset.borderThickness))) {
          // Bottom wall
          while (!this.addThang({
            'id': this.getRandomThang(clusters[preset.borders].thangs),
            'pos': {
              'x': i + (preset.borderSize/2) + (noiseFactor * _.random(-thangSizes.borderSize.x/2, thangSizes.borderSize.x/2)),
              'y': 0 + (preset.borderSize/2) + (noiseFactor * _.random(-thangSizes.borderSize.y/2, thangSizes.borderSize.y))
            },
            'margin': clusters[preset.borders].margin
          })) {
            continue;
          }

          // Top wall
          while (!this.addThang({
            'id': this.getRandomThang(clusters[preset.borders].thangs),
            'pos': {
              'x': i + (preset.borderSize/2) + (noiseFactor * _.random(-thangSizes.borderSize.x/2, thangSizes.borderSize.x/2)),
              'y': (presetSize.y - (preset.borderSize/2)) + (noiseFactor * _.random(-thangSizes.borderSize.y, thangSizes.borderSize.y/2))
            },
            'margin': clusters[preset.borders].margin
          })) {
            continue;
          }

          // Double wall on top
          if (preset.type === 'dungeon') {
            this.addThang({
              'id': this.getRandomThang(clusters[preset.borders].thangs),
              'pos': {
                'x': i + (preset.borderSize/2),
                'y': presetSize.y - ((3 * preset.borderSize)/2)
              },
              'margin': clusters[preset.borders].margin
            });
            if ((( i / preset.borderSize ) % 2) && (i !== (presetSize.x - thangSizes.borderSize.x))) {
              this.addThang({
                'id': this.getRandomThang(clusters['torch'].thangs),
                'pos': {
                  'x': i + preset.borderSize,
                  'y': presetSize.y - (preset.borderSize / 2)
                },
                'margin': clusters['torch'].margin
              });
            } else if (((( i / preset.borderSize ) % 2) === 0) && i && (_.random(100) < 30)) {
              this.addThang({
                'id': this.getRandomThang(clusters['chains'].thangs),
                'pos': {
                  'x': i + preset.borderSize,
                  'y': presetSize.y - (preset.borderSize / 2)
                },
                'margin': clusters['chains'].margin
              });
            }
          }
        }
      }

      return (() => {
        const result = [];
        for (i of Array.from(_.range(0, presetSize.y, thangSizes.borderSize.y))) {
          result.push((() => {
            const result1 = [];
            for (j of Array.from(_.range(preset.borderThickness))) {
            // Left wall
              while (!this.addThang({
                'id': this.getRandomThang(clusters[preset.borders].thangs),
                'pos': {
                  'x': 0 + (preset.borderSize/2) + (noiseFactor * _.random(-thangSizes.borderSize.x/2, thangSizes.borderSize.x)),
                  'y': i + (preset.borderSize/2) + (noiseFactor * _.random(-thangSizes.borderSize.y/2, thangSizes.borderSize.y/2))
                },
                'margin': clusters[preset.borders].margin
              })) {
                continue;
              }

              // Right wall
              result1.push((() => {
                const result2 = [];
                while (!this.addThang({
                'id': this.getRandomThang(clusters[preset.borders].thangs),
                'pos': {
                  'x': (presetSize.x - (preset.borderSize/2)) + (noiseFactor * _.random(-thangSizes.borderSize.x, thangSizes.borderSize.x/2)),
                  'y': i + (preset.borderSize/2) + (noiseFactor * _.random(-thangSizes.borderSize.y/2, thangSizes.borderSize.y/2))
                },
                'margin': clusters[preset.borders].margin
              })) {
                  continue;
                }
                return result2;
              })());
            }
            return result1;
          })());
        }
        return result;
      })();
    }

    generateDecorations(preset, presetSize){
      return (() => {
        const result = [];
        for (var name in preset.decorations) {
          var decoration = preset.decorations[name];
          result.push((() => {
            const result1 = [];
            for (var num of Array.from(_.range(presetSize.sizeFactor * _.random(decoration.num[0], decoration.num[1])))) {
              var rect;
              if (this['build'+name] !== undefined) {
                this['build'+name](preset, presetSize, decoration);
                continue;
              }
              while (true) {
                rect = {
                  'x':_.random((decoration.width/2) + (preset.borderSize/2) + thangSizes.borderSize.x, presetSize.x - (decoration.width/2) - (preset.borderSize/2) - thangSizes.borderSize.x),
                  'y':_.random((decoration.height/2) + (preset.borderSize/2) + thangSizes.borderSize.y, presetSize.y - (decoration.height/2) - (preset.borderSize/2) - thangSizes.borderSize.y),
                  'width':decoration.width,
                  'height':decoration.height
                };
                if (this.addRect(rect)) { break; }
              }

              result1.push((() => {
                const result2 = [];
                for (var cluster in decoration.clusters) {
                  var range = decoration.clusters[cluster];
                  result2.push(Array.from(_.range(_.random(range[0], range[1]))).map((i) =>
                    (() => {
                      const result3 = [];
                      while (!this.addThang({
                      'id':this.getRandomThang(clusters[cluster].thangs),
                      'pos':{
                        'x':_.random(rect.x - (rect.width/2), rect.x + (rect.width/2)),
                        'y':_.random(rect.y - (rect.height/2), rect.y + (rect.height/2))
                      },
                      'margin':clusters[cluster].margin
                    })) {
                        continue;
                      }
                      return result3;
                    })()));
                }
                return result2;
              })());
            }
            return result1;
          })());
        }
        return result;
      })();
    }

    buildRoom(preset, presetSize, room) {
      let i, rect, roomThickness, t;
      const grid = preset.borderSize;
      while (true) {
        rect = {
          'width':presetSize.sizeFactor * (room.width[0] + (grid * _.random(0, (room.width[1] - room.width[0])/grid))),
          'height':presetSize.sizeFactor * (room.height[0] + (grid * _.random(0, (room.height[1] - room.height[0])/grid)))
        };
        // This logic isn't quite right--it makes the rooms bigger than intended--but it's snapping correctly, which is fine for now.
        rect.width = (Math.round((rect.width - grid) / (2 * grid)) * 2 * grid) + grid;
        rect.height = (Math.round((rect.height - grid) / (2 * grid)) * 2 * grid) + grid;
        roomThickness = _.random(room.thickness[0], room.thickness[1]);
        rect.x = _.random((rect.width/2) + (grid * (roomThickness+1.5)), presetSize.x - (rect.width/2) - (grid * (roomThickness+1.5)));
        rect.y = _.random((rect.height/2) + (grid * (roomThickness+2.5)), presetSize.y - (rect.height/2) - (grid * (roomThickness+3.5)));
        // Snap room walls to the wall grid.
        rect.x = Math.round((rect.x - (grid / 2)) / grid) * grid;
        rect.y = Math.round((rect.y - (grid / 2)) / grid) * grid;
        if (this.addRect({
          'x': rect.x,
          'y': rect.y,
          'width': rect.width + (2.5 * roomThickness * grid),
          'height': rect.height + (2.5 * roomThickness * grid)
        })) { break; }
      }

      const xRange = _.range((rect.x - (rect.width/2)) + grid, rect.x + (rect.width/2), grid);
      const topDoor = _.random(1) > 0.5;
      const topDoorX = xRange[_.random(0, xRange.length-1)];
      const bottomDoor = !topDoor ? true : _.random(1) > 0.5;
      const bottomDoorX = xRange[_.random(0, xRange.length-1)];

      for (t of Array.from(_.range(0, roomThickness+1))) {
        for (i of Array.from(_.range(rect.x - (rect.width/2) - ((t-1) * grid), rect.x + (rect.width/2) + (t * grid), grid))) {
          // Bottom wall
          var thang = {
            'id': this.getRandomThang(clusters[room.cluster].thangs),
            'pos': {
              'x': i,
              'y': rect.y - (rect.height/2) - (t * grid)
            },
            'margin': clusters[room.cluster].margin
          };
          if ((i === bottomDoorX) && bottomDoor) {
            thang.id = this.getRandomThang(clusters['doors'].thangs);
            thang.pos.y -= grid/3;
          }
          if ((i !== bottomDoorX) || (t === roomThickness) || !bottomDoor) { this.addThang(thang); }

          if ((t === roomThickness) && (i !== (rect.x - (rect.width/2) - ((t-1) * grid))) && (preset.type === 'dungeon')) {
            if (( (i !== bottomDoorX) && (i !== (bottomDoorX + grid)) ) || !bottomDoor) {
              this.addThang({
                'id': this.getRandomThang(clusters['torch'].thangs),
                'pos': {
                  'x': thang.pos.x - (grid / 2),
                  'y': thang.pos.y + grid
                },
                'margin': clusters['torch'].margin
              });
            }
          }

          // Top wall
          thang = {
            'id': this.getRandomThang(clusters[room.cluster].thangs),
            'pos': {
              'x': i,
              'y': rect.y + (rect.height/2) + (t * grid)
            },
            'margin': clusters[room.cluster].margin
          };
          if ((i === topDoorX) && topDoor) {
            thang.id = this.getRandomThang(clusters['doors'].thangs);
            thang.pos.y -= grid;
          }
          if ((i !== topDoorX) || (t === roomThickness) || !topDoor) { this.addThang(thang); }
        }
      }

      return (() => {
        const result = [];
        for (t of Array.from(_.range(0, roomThickness))) {
          result.push((() => {
            const result1 = [];
            for (i of Array.from(_.range(rect.y - (rect.height/2) - (t * grid), rect.y + (rect.height/2) + ((t+1) * grid), grid))) {
            // Left wall
              this.addThang({
                'id': this.getRandomThang(clusters[room.cluster].thangs),
                'pos': {
                  'x': rect.x - (rect.width/2) - (t * grid),
                  'y': i
                },
                'margin': clusters[room.cluster].margin
              });

              // Right wall
              result1.push(this.addThang({
                'id': this.getRandomThang(clusters[room.cluster].thangs),
                'pos': {
                  'x': rect.x + (rect.width/2) + (t * grid),
                  'y': i
                },
                'margin': clusters[room.cluster].margin
              }));
            }
            return result1;
          })());
        }
        return result;
      })();
    }

    buildBarrels(preset, presetSize, decoration) {
      let rect = {
        'width':presetSize.sizeFactor * ( _.random( decoration.width[0], decoration.width[1] ) ),
        'height':presetSize.sizeFactor * ( _.random( decoration.height[0], decoration.height[1] ) )
      };
      const x = [ (rect.width/2) + preset.borderSize , presetSize.x - (rect.width/2) - preset.borderSize ];
      const y = [ (rect.height/2) + preset.borderSize , presetSize.y - (rect.height/2) - (2 * preset.borderSize) ];

      return Array.from(x).map((i) =>
        (() => {
          const result = [];
          for (var j of Array.from(y)) {
            if (_.random(100) < 40) {
              rect = {
                'x': i,
                'y': j,
                'width': rect.width,
                'height': rect.height
              };
              if (this.addRect(rect)) {
                result.push(Array.from(_.range( _.random( decoration.numBarrels[0], decoration.numBarrels[1] ) )).map((num) =>
                  (() => {
                    const result1 = [];
                    while (!this.addThang({
                    'id': this.getRandomThang(clusters[decoration.cluster].thangs),
                    'pos': {
                      'x': _.random(rect.x - (rect.width/2), rect.x + (rect.width/2)),
                      'y': _.random(rect.y - (rect.height/2), rect.y + (rect.height/2))
                    },
                    'margin': clusters[decoration.cluster].margin
                  })) {
                      continue;
                    }
                    return result1;
                  })()));
              } else {
                result.push(undefined);
              }
            } else {
              result.push(undefined);
            }
          }
          return result;
        })());
    }

    addThang(thang) {
      if (this.falseCount > 100) {
        console.log('infinite loop', thang);
        this.falseCount = 0;
        return true;
      }
      for (var existingThang of Array.from(this.thangs)) {
        if ((existingThang.margin === -1) || (thang.margin === -1)) {
          continue;
        }
        if ((Math.abs(existingThang.pos.x - thang.pos.x) < (thang.margin + existingThang.margin)) && (Math.abs(existingThang.pos.y - thang.pos.y) < (thang.margin + existingThang.margin))) {
          this.falseCount++;
          return false;
        }
      }
      this.thangs.push(thang);
      return true;
    }

    addRect(rect) {
      if (this.falseCount > 100) {
        console.log('infinite loop', rect);
        this.falseCount = 0;
        return true;
      }
      for (var existingRect of Array.from(this.rects)) {
        if ((Math.abs(existingRect.x - rect.x) <= ((rect.width/2) + (existingRect.width/2))) && (Math.abs(existingRect.y - rect.y) <= ((rect.height/2) + (existingRect.height/2)))) {
          this.falseCount++;
          return false;
        }
      }
      this.rects.push(rect);
      return true;
    }

    getRandomThang(thangList) {
      return thangList[_.random(0, thangList.length-1)];
    }

    onHidden() {
      if (this.reloadOnClose) { return location.reload(); }
    }
  };
  GenerateTerrainModal.initClass();
  return GenerateTerrainModal;
})());
