c = require 'schemas/schemas'

module.exports =
  'world:won': c.object {},
    replacedNoteChain: {type: 'array'}

  'world:thang-died': c.object {required: ['thang', 'killer']},
    replacedNoteChain: {type: 'array'}
    thang: {type: 'object'}
    killer: {type: 'object'}
    killerHealth: {type: ['number', 'undefined']}
    maxHealth: {type: 'number'}

  'world:thang-touched-goal': c.object {required: ['actor', 'touched']},
    replacedNoteChain: {type: 'array'}
    thang: {type: 'object'}
    actor: {type: 'object'}
    touched: {type: 'object'}

  'world:thang-collected-item': c.object {required: ['actor', 'item']},
    replacedNoteChain: {type: 'array'}
    thang: {type: 'object'}
    actor: {type: 'object'}
    item: {type: 'object'}

  'world:thang-finished-plans': c.object {required: ['thang']},
    replacedNoteChain: {type: 'array'}
    thang: {type: 'object'}

  'world:attacked-when-out-of-range': c.object {required: ['thang']},
    replacedNoteChain: {type: 'array'}
    thang: {type: 'object'}

  'world:custom-script-trigger': {type: 'object'}

  'world:user-code-problem': c.object {required: ['thang', 'problem']},
    thang: {type: 'object'}
    problem: c.object {required: ['message', 'level', 'type']},  #, 'userInfo', 'error']},
      userInfo: {type: 'object'}
      message: {type: 'string'}
      level: {type: 'string', enum: ['info', 'warning', 'error']}
      type: {type: 'string'}
      error: {type: 'object'}

  'world:lines-of-code-counted': c.object {required: ['thang', 'linesUsed']},
    thang: {type: 'object'}
    linesUsed: {type: 'integer'}
