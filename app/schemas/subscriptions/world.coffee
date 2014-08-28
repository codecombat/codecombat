c = require 'schemas/schemas'

module.exports =
  'world:won': c.object {},
    replacedNoteChain: {type: 'array'}

  'world:thang-died': c.object {required: ['thang', 'killer']},
    replacedNoteChain: {type: 'array'}
    thang: {type: 'object'}
    killer: {type: 'object'}

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
