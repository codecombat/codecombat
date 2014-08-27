c = require 'schemas/schemas'

module.exports =
  'editor:save-new-version': c.object {title: 'Save New Version', description: 'Published when a version gets saved', required: ['major', 'commitMessage']},
    major: {type: 'boolean'}
    commitMessage: {type: 'string'}

  'editor:view-switched': c.object {title: 'Level View Switched', description: 'Published whenever the view switches'}

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

  'editor:level-thang-edited': c.object {required: ['thangID', 'thangData']},
    thangID: {type: 'string'}
    thangData: {type: 'object'}

  'editor:level-thang-done-editing': c.object {}

  'editor:level-loaded': c.object {required: ['level']},
    level: {type: 'object'}

  'level:reload-from-data': c.object {required: ['level', 'supermodel']},
    level: {type: 'object'}
    supermodel: {type: 'object'}

  'level:reload-thang-type': c.object {required: ['thangType']},
    thangType: {type: 'object'}

  'editor:random-terrain-generated': c.object {required: ['thangs']},
    thangs: c.array {}, {type: 'object'}
