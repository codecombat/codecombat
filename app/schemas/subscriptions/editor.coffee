c = require 'schemas/schemas'

module.exports =
  'editor:campaign-analytics-modal-closed': c.object {title: 'Campaign editor analytics modal closed'},
    targetLevelSlug: {type: 'string'}

  'editor:view-switched': c.object {title: 'Level View Switched', description: 'Published whenever the view switches'},
    targetURL: {type: 'string'}

  'editor:level-component-editing-ended': c.object {required: ['component']},
    component: {type: 'object'}

  'editor:edit-level-system': c.object {required: ['original', 'majorVersion']},
    original: {type: 'string'}
    majorVersion: {type: 'integer', minimum: 0}

  'editor:level-system-added': c.object {required: ['system']},
    system: {type: 'object'}

  'editor:level-system-editing-ended': c.object {required: ['system']},
    system: {type: 'object'}

  'editor:edit-level-thang': c.object {required: ['thangID']},
    thangID: {type: 'string'}

  'editor:level-thang-edited': c.object {required: ['thangData', 'oldPath']},
    thangData: {type: 'object'}
    oldPath: {type: 'string'}

  'editor:level-thang-done-editing': c.object {required: ['thangData', 'oldPath']},
    thangData: {type: 'object'}
    oldPath: {type: 'string'}

  'editor:thangs-edited': c.object {required: ['thangs']},
    thangs: c.array {}, {type: 'object'}

  'editor:level-loaded': c.object {required: ['level']},
    level: {type: 'object'}

  'level:reload-from-data': c.object {required: ['level', 'supermodel']},
    level: {type: 'object'}
    supermodel: {type: 'object'}

  'level:reload-thang-type': c.object {required: ['thangType']},
    thangType: {type: 'object'}

  'editor:random-terrain-generated': c.object {required: ['thangs', 'terrain']},
    thangs: c.array {}, {type: 'object'}
    terrain: c.terrainString

  'editor:terrain-changed': c.object {required: ['terrain']},
    terrain:
      oneOf: [
        c.terrainString
        {type: ['null', 'undefined']}
      ]

  'editor:thang-type-kind-changed': c.object {required: ['kind']},
    kind: {type: 'string'}

  'editor:thang-type-color-groups-changed': c.object {required: ['colorGroups']},
    colorGroups: {type: 'object'}
