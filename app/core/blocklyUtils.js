const utils = require('core/utils')
const Blockly = require('blockly')

// Code generators. (Blockly does not have generators for CoffeeScript, C++, Java, or HTML.)
const BlocklyPython = require('blockly/python') // eslint-disable-line no-unused-vars
const BlocklyJavaScript = require('blockly/javascript') // eslint-disable-line no-unused-vars
const BlocklyLua = require('blockly/lua') // eslint-disable-line no-unused-vars

// Plugins
require('@blockly/block-plus-minus')
const { ContinuousToolbox, ContinuousFlyout, ContinuousMetrics } = require('@blockly/continuous-toolbox')
const { CrossTabCopyPaste } = require('@blockly/plugin-cross-tab-copy-paste')
// { ZoomToFitControl } = require '@blockly/zoom-to-fit'  # Not that useful unless we increase zoom level range

module.exports.createBlocklyToolbox = function ({ propertyEntryGroups, generator, codeLanguage, codeFormat, level }) {
  if (!codeLanguage) { codeLanguage = 'javascript' }
  const commentStart = utils.commentStarts[codeLanguage] || '//'
  generator = module.exports.getBlocklyGenerator(codeLanguage)
  // generator.STATEMENT_PREFIX = "#{commentStart} highlightBlock(%1)\n"  # TODO: can we highlight running blocks another way?
  generator.INDENT = '    '

  let superBasicLevels = ['dungeons-of-kithgard', 'gems-in-the-deep', 'shadow-guard']
  if (me.level() > 5) {
    superBasicLevels = [] // Coming back to them later should allow basic misc blocks
  }

  const userBlockCategories = []

  const mergedPropertyEntryGroups = {}
  for (const owner in propertyEntryGroups) {
    // Merge groups like "Hero", "Hero 2", Hero 3" all into "Hero"
    const ownerName = owner.replace(/ \d+$/, '')
    if (mergedPropertyEntryGroups[ownerName]) {
      mergedPropertyEntryGroups[ownerName].props = mergedPropertyEntryGroups[ownerName].props.slice().concat(propertyEntryGroups[owner].props.slice())
    } else {
      mergedPropertyEntryGroups[ownerName] = _.clone(propertyEntryGroups[owner])
    }
  }

  const propNames = new Set()
  for (const owner in mergedPropertyEntryGroups) {
    for (const prop of mergedPropertyEntryGroups[owner].props) {
      propNames.add(prop.name)
    }
    if (/programmaticon/i.test(owner)) continue
    const userBlocks = mergedPropertyEntryGroups[owner].props.map(prop =>
      createBlock({ owner, prop, generator, codeLanguage, codeFormat, level, superBasicLevels })
    )
    userBlockCategories.push({ kind: 'category', name: owner, colour: '190', contents: userBlocks })
  }

  const newlineBlock = {
    type: 'newline',
    message0: '(newline)',
    args0: [],
    previousStatement: null,
    nextStatement: null,
    colour: 180,
    tooltip: 'Newline'
  }
  Blockly.Blocks.newline = { init () { return this.jsonInit(newlineBlock) } }
  generator.forBlock.newline = function (block) {
    return `\n`
  }

  // TODO: Make this yellow, custom rendering, more obvious entry point, like yellow arrows
  const entryPointBlock = {
    type: 'entry_point',
    message0: 'Code\nHere%1',
    args0: [{ type: 'input_statement', name: 'ENTRY_POINT' }],
    previousStatement: null,
    nextStatement: null,
    colour: 270,
    tooltip: 'Code Here'
  }
  Blockly.Blocks.entry_point = { init () { return this.jsonInit(entryPointBlock) } }
  generator.forBlock.entry_point = function (block) {
    let text = (generator.statementToCode(block, 'ENTRY_POINT') || '') + '\n'
    text = text.trim().split('\n').map((line) => `${line.replace(/^ {4}/g, '')}`).join('\n') + '☃\n' // Add unicode snowman to avoid trimming
    return text
  }

  const commentBlock = {
    type: 'comment',
    message0: '%1',
    args0: [{ type: 'field_label_serializable', name: 'COMMENT', text: 'Comment', 'class': 'comment-block' }],
    previousStatement: null,
    nextStatement: null,
    colour: 180,
    tooltip: 'Comment'
  }
  Blockly.Blocks.comment = { init () { return this.jsonInit(commentBlock) } }
  generator.forBlock.comment = function (block) {
    const text = block.getFieldValue('COMMENT')
    return `${commentStart} ${text}\n`
  }

  const codeCommentBlock = {
    type: 'code_comment',
    message0: 'Commented %1',
    args0: [{ type: 'input_statement', name: 'CODE_COMMENT' }],
    inputsInline: true,
    previousStatement: null,
    nextStatement: null,
    colour: 180,
    tooltip: 'Commented-out code will have no effect'
  }
  Blockly.Blocks.code_comment = { init () { return this.jsonInit(codeCommentBlock) } }
  generator.forBlock.code_comment = function (block) {
    const text = generator.statementToCode(block, 'CODE_COMMENT')
    if (!text) { return '' }
    return text.trim().split('\n').map((line) => `${commentStart}${line.replace(/^ {4}/g, '')}`).join('\n') + '\n'
  }

  const mathOrStringArithmeticBlock = {
    type: 'math_or_string_arithmetic',
    message0: '%1 %2 %3',
    args0: [
      {
        type: 'input_value',
        name: 'A',
        // check: 'Number',
      },
      {
        type: 'field_dropdown',
        name: 'OP',
        options: [
          ['+', 'ADD'],
          ['-', 'MINUS'],
          ['×', 'MULTIPLY'],
          ['÷', 'DIVIDE'],
          ['^', 'POWER'],
        ],
      },
      {
        type: 'input_value',
        name: 'B',
        // 'check': 'Number',
      },
    ],
    inputsInline: true,
    output: 'Number', // TODO: number or string?
    style: 'math_blocks',
    helpUrl: '%{BKY_MATH_ARITHMETIC_HELPURL}',
    extensions: ['math_op_tooltip'],
    // colour: 180,
  }
  Blockly.Blocks.math_or_string_arithmetic = { init () { return this.jsonInit(mathOrStringArithmeticBlock) } }
  generator.forBlock.math_or_string_arithmetic = function (block) {
    // Basic arithmetic operators, and power.
    const OPERATORS = {
      ADD: [' + ', 6.2],
      MINUS: [' - ', 6.1],
      MULTIPLY: [' * ', 5.1],
      DIVIDE: [' / ', 5.2],
      POWER: [' ** ', 5.0],
    }
    const tuple = OPERATORS[block.getFieldValue('OP')]
    const operator = tuple[0]
    const order = tuple[1]
    const argument0 = generator.valueToCode(block, 'A', order) || '0'
    const argument1 = generator.valueToCode(block, 'B', order) || '0'
    const code = argument0 + operator + argument1
    return [code, order]
  }

  const untypedForEachBlock = {
    type: 'controls_forEach', // Overwrite built-in block so that break/continue recognize it
    message0: '%{BKY_CONTROLS_FOREACH_TITLE}',
    args0: [
      {
        type: 'field_variable',
        name: 'VAR',
        variable: null,
      },
      {
        type: 'input_value',
        name: 'LIST',
        // check: 'Array',
      },
    ],
    message1: '%{BKY_CONTROLS_REPEAT_INPUT_DO} %1',
    args1: [
      {
        type: 'input_statement',
        name: 'DO',
      },
    ],
    previousStatement: null,
    nextStatement: null,
    style: 'loop_blocks',
    helpUrl: '%{BKY_CONTROLS_FOREACH_HELPURL}',
    extensions: [
      'contextMenu_newGetVariableBlock',
      'controls_forEach_tooltip',
    ],
  }
  Blockly.Blocks.controls_forEach = { init () { return this.jsonInit(untypedForEachBlock) } }

  const dropdownRepeatBlock = {
    type: 'controls_repeat_dropdown',
    message0: `%{BKY_CONTROLS_REPEAT_TITLE}%2%{BKY_CONTROLS_REPEAT_INPUT_DO}%3`,
    args0: [
      {
        type: 'field_dropdown',
        name: 'TIMES',
        options: [
          ['1', '1'],
          ['2', '2'],
          ['3', '3'],
          ['4', '4'],
          ['5', '5'],
          ['6', '6'],
          ['7', '7'],
        ]
      },
      {
        type: 'input_dummy',
      },
      {
        type: 'input_statement',
        name: 'DO',
      },
    ],
    previousStatement: null,
    nextStatement: null,
    colour: '%{BKY_LOOPS_HUE}',
    tooltip: '%{BKY_CONTROLS_REPEAT_TOOLTIP}',
    helpUrl: '%{BKY_CONTROLS_REPEAT_HELPURL}',
  }
  Blockly.Blocks.controls_repeat_dropdown = { init () { return this.jsonInit(dropdownRepeatBlock) } }
  generator.forBlock.controls_repeat_dropdown = generator.forBlock.controls_repeat

  const returnBlock = {
    type: 'procedures_return',
    message0: 'return %1',
    args0: [
      {
        type: 'input_value',
        name: 'VALUE',
        // check: 'Number',
      }
    ],
    previousStatement: null,
    inputsInline: true,
    style: 'procedure_blocks',
    // helpUrl: '%{BKY_PROCEDURES_IFRETURN_HELPURL}', // ??
    // helpUrl: '%{PROCEDURES_IFRETURN_HELPURL}', // ??
    // extensions: ['math_op_tooltip'],
    // colour: 180,
  }
  Blockly.Blocks.procedures_return = { init () { return this.jsonInit(returnBlock) } }
  generator.forBlock.procedures_return = function (block) {
    const returnValue = generator.valueToCode(block, 'VALUE', generator.ORDER_CONDITIONAL)
    if (returnValue) {
      return 'return ' + returnValue + ';\n'
    } else {
      return 'return;\n'
    }
  }

  // Need a block to handle code that we couldn't properly convert to a block
  const rawCodeBlock = {
    type: 'raw_code',
    message0: '%1',
    args0: [
      {
        type: 'field_multilinetext',
        name: 'CODE',
        check: 'String',
        text: "Couldn't read code."
      }
    ],
    previousStatement: null,
    nextStatement: null,
    // inputsInline: true,
    colour: 1,
  }
  Blockly.Blocks.raw_code = { init () { return this.jsonInit(rawCodeBlock) } }
  generator.forBlock.raw_code = function (block) {
    const value = (block.getFieldValue('CODE') || '') + '\n'
    return value
  }

  // Also need one that has output
  const rawCodeValueBlock = {
    type: 'raw_code_value',
    message0: '%1',
    args0: [
      {
        type: 'field_input',
        name: 'CODE',
        check: 'String',
      }
    ],
    output: null,
    // inputsInline: true,
    colour: 1,
  }
  Blockly.Blocks.raw_code_value = { init () { return this.jsonInit(rawCodeValueBlock) } }
  generator.forBlock.raw_code_value = function (block) {
    const text = block.getFieldValue('CODE')
    return [text, generator.ORDER_ATOMIC]
  }

  // Need a block to convert statements like `hero.summon('soldier')` when Blockly expects them to be expressions and use return values
  const expressionStatementBlock = {
    type: 'expression_statement',
    message0: '%1',
    args0: [
      {
        type: 'input_value',
        name: 'EXPRESSION',
      }
    ],
    previousStatement: null,
    nextStatement: null,
    inputsInline: true,
    colour: 1,
  }
  Blockly.Blocks.expression_statement = { init () { return this.jsonInit(expressionStatementBlock) } }
  generator.forBlock.expression_statement = function (block) {
    const value = generator.valueToCode(block, 'EXPRESSION', generator.ORDER_CONDITIONAL) + '\n'
    return value
  }

  // Need a block to handle `range(1, 10)` and `range(1, 100, 10)` kind of Python ranges
  const rangeBlock = {
    type: 'lists_range',
    message0: 'range(%1, %2, %3)',
    args0: [
      {
        type: 'input_value',
        name: 'START',
        check: 'Number',
      },
      {
        type: 'input_value',
        name: 'END',
        check: 'Number',
      },
      {
        type: 'input_value',
        name: 'INCREMENT',
        check: 'Number',
      },
    ],
    inputsInline: true,
    output: 'Array',
    style: 'list_blocks',
    // colour: 180,
  }
  Blockly.Blocks.lists_range = { init () { return this.jsonInit(rangeBlock) }, setupInfo: { args0: rangeBlock.args0 } }
  generator.forBlock.lists_range = function (block) {
    const start = generator.valueToCode(block, 'START', generator.ORDER_ATOMIC) || 0
    const end = generator.valueToCode(block, 'END', generator.ORDER_ATOMIC) || 10
    const increment = generator.valueToCode(block, 'INCREMENT', generator.ORDER_ATOMIC) || 1
    const code = `range(${start}, ${end}, ${increment})`
    return [code, generator.ORDER_ATOMIC]
  }

  const miscBlocks = [
    createBlock({
      owner: 'hero',
      generator,
      codeLanguage,
      codeFormat,
      level,
      prop: {
        name: 'say',
        owner: 'this',
        args: [{ name: 'what' /* type: string' */ }], // TODO: can we do String or Number? is it String or string?
        type: 'function'
      },
      include () {
        const slug = level?.get('slug')
        if (!slug) {
          return true
        }
        return !superBasicLevels.includes(slug) && (slug === 'wakka-maul' || !level.isLadder()) && level?.get('product') !== 'codecombat-junior'
      }
    }),
    createBlock({
      owner: 'hero',
      generator,
      codeLanguage,
      codeFormat,
      level,
      prop: { type: 'ref' },
      include () {
        // TODO: better targeting of when we introduce this (hero used as a value)
        return propNames.has('if/else') && level?.get('product') !== 'codecombat-junior'
      }
    })
  ]
  if (miscBlocks.filter(prop => prop.include()).length) {
    userBlockCategories.push({ kind: 'category', name: 'Misc', colour: '190', contents: miscBlocks })
  }

  const builtInBlockCategories = [
    {
      kind: 'category',
      name: 'Logic',
      colour: '290',
      contents: [
        { kind: 'block', type: 'controls_if', include () { return propNames.has('if/else') } },
        { kind: 'block', type: 'controls_if', extraState: { hasElse: true }, include () { return propNames.has('else') } },
        { kind: 'block', type: 'controls_if', extraState: { elseIfCount: 1, hasElse: 1 }, include () { return propNames.has('else') } }, // TODO: better if/elseif/else differentiation?
        { kind: 'block', type: 'logic_compare', include () { return propNames.has('else') } }, // TODO: better targeting of when we introduce this logic?
        { kind: 'block', type: 'logic_operation', include () { return propNames.has('else') } }, // TODO: better targeting of when we introduce this logic?
        { kind: 'block', type: 'logic_negate', include () { return propNames.has('else') } }, // TODO: better targeting of when we introduce this logic?
        // { kind: 'block', type: 'math_arithmetic', include () { return propNames.has('else') } } // TODO: better targeting of when we introduce this logic?
        { kind: 'block', type: 'math_or_string_arithmetic', include () { return propNames.has('else') } }, // TODO: better targeting of when we introduce this logic?
        { kind: 'block', type: 'procedures_return', include () { return propNames.has('else') } }, // TODO: when to introduce? also move this to procedures
        { kind: 'block', type: 'expression_statement', include () { return propNames.has('summon') } }, // TODO: move this
        { kind: 'block', type: 'lists_range', include () { return propNames.has('else') } }, // TODO: better targeting of when we introduce this logic? Also, move this. Also, make sure it's not available in JavaScript (but is available hidden, for prepareBlockIntelligence)
      ]
    },
    {
      kind: 'category',
      name: 'Loops',
      colour: '290',
      contents: [
        {
          kind: 'block',
          type: 'controls_whileUntil',
          fields: {
            MODE: 'WHILE'
          },
          inputs: {
            BOOL: {
              block: { type: 'logic_boolean', fields: { BOOL: 'true' } }
            }
          },
          include () { return propNames.has('while-true loop') }
        },
        // { kind: 'block', type: 'controls_whileUntil', include: -> propNames.has('while-loop') }  # Redundant, since while-true can just delete true
        { kind: 'block', type: 'controls_repeat_ext', inputs: { TIMES: { block: { type: 'math_number', fields: { NUM: 3 } } } }, include () { return propNames.has('for-loop') && level?.get('product') !== 'codecombat-junior' }, includeCodeToBlocks () { return level?.get('product') !== 'codecombat-junior' } },
        { kind: 'block', type: 'controls_repeat_dropdown', fields: { TIMES: '3' }, include () { return propNames.has('for-loop') && level?.get('product') === 'codecombat-junior' }, includeCodeToBlocks () { return level?.get('product') === 'codecombat-junior' } },
        // { kind: 'block', type: 'controls_for', include: -> propNames.has('for-loop') }  # Too wide  # TODO: introduce this later than the simpler repeat_ext loop above? Or just use this one, but defaults start at 0 and increment by 1?
        // { kind: 'block', type: 'controls_forEach', include () { return propNames.has('for-in-loop') } },  // TODO: use sometimes?
        { kind: 'block', type: 'controls_forEach', include () { return propNames.has('for-in-loop') } }, // TODO: better targeting of when we introduce this logic? Also, move this. Also, think about Python vs. JS and the general typed array forEach
        { kind: 'block', type: 'controls_flow_statements', include () { return propNames.has('break') } },
        // { kind: 'block', type: 'controls_flow_statements', fields: { FLOW: 'CONTINUE' }, include () { return propNames.has('continue') } }  // Wide, should figure out how to not have this
        { kind: 'block', type: 'controls_flow_statements', fields: { FLOW: 'CONTINUE' }, include () { return false } }, // Only in full block toolbox, not shown to user
      ]
    },
    {
      kind: 'category',
      name: 'Literals',
      colour: '10',
      contents: [
        { kind: 'block', type: 'text', include () { return !superBasicLevels.includes(level?.get('slug')) && level?.get('product') !== 'codecombat-junior' } },
        { kind: 'block', type: 'math_number', include () { return !superBasicLevels.includes(level?.get('slug')) && level?.get('product') !== 'codecombat-junior' } },
        { kind: 'block', type: 'logic_boolean', include () { return propNames.has('if/else') } }, // TODO: better targeting of when we introduce this logic?
        { kind: 'block', type: 'logic_null', include () { return propNames.has('else') } }, // TODO: better targeting of when we introduce this logic?
        { kind: 'block', type: 'newline', include () { return false } },
        { kind: 'block', type: 'entry_point', include () { return false } }, // TODO: organize
        { kind: 'block', type: 'comment', include () { return false } },
        { kind: 'block', type: 'code_comment', include () { return false } },
        { kind: 'block', type: 'logic_ternary', include () { return false } },
      ]
    },
    {
      kind: 'category',
      name: 'Lists',
      colour: '10',
      contents: [
        { kind: 'block', type: 'lists_create_empty', include () { return propNames.has('arrays') } },
        { kind: 'block', type: 'lists_create_with', include () { return propNames.has('arrays') } },
        { kind: 'block', type: 'lists_length', include () { return propNames.has('arrays') } },
        { kind: 'block', type: 'text_length', include () { return propNames.has('arrays') } }, // TODO: make a general version, determine when to use
        { kind: 'block', type: 'lists_isEmpty', include () { return propNames.has('arrays') } },
        // Removing wide blocks for now until we have a way to handle them in continuous flyout
        // { kind: 'block', type: 'lists_repeat', inputs: { NUM: { block: { type: 'math_number', fields: { NUM: '5' } } } }, include () { return propNames.has('arrays') } },
        // { kind: 'block', type: 'lists_indexOf', include () { return propNames.has('arrays') } },
        // { kind: 'block', type: 'lists_getIndex', include () { return propNames.has('arrays') } },
        // { kind: 'block', type: 'lists_setIndex', include () { return propNames.has('arrays') } },
        { kind: 'block', type: 'lists_repeat', inputs: { NUM: { block: { type: 'math_number', fields: { NUM: '5' } } } }, include () { return false } },
        { kind: 'block', type: 'lists_indexOf', include () { return false } },
        { kind: 'block', type: 'lists_getIndex', include () { return false } },
        { kind: 'block', type: 'lists_setIndex', include () { return false } },
        // Some of the extra list operations
        { kind: 'block', type: 'lists_getSublist', include () { return propNames.has('arrays') && false } }, // TODO: better targeting of when we introduce this logic?
        { kind: 'block', type: 'lists_split', include () { return propNames.has('arrays') && false } }, // TODO: better targeting of when we introduce this logic?
        { kind: 'block', type: 'lists_sort', include () { return propNames.has('arrays') && false } }, // TODO: better targeting of when we introduce this logic?
        { kind: 'block', type: 'raw_code_value', include () { return false } },
        { kind: 'block', type: 'raw_code', include () { return false } }, // Put this last so it's the one that shows up when code doesn't parse (not sure why)
      ]
    },
    {
      kind: 'category',
      name: 'Variables',
      colour: '50',
      custom: 'VARIABLE',
      include () { return propNames.has('while-true loop') || propNames.has('while-loop') } // TODO: better targeting of when we introduce this logic? It's after while-true loops, but doesn't have own 'variables' entry in Programmaticon
    },
    {
      kind: 'category',
      name: 'User Functions',
      colour: '50',
      custom: 'PROCEDURE',
      include () { return propNames.has('functions') }
    },
  ]

  let blockCategories = userBlockCategories.concat(builtInBlockCategories)
  const fullBlockCategories = _.cloneDeep(userBlockCategories.concat(builtInBlockCategories))

  for (const category of blockCategories) {
    if (category.contents) {
      // Hide irrelevant, non-included blocks from the player
      category.contents = category.contents.filter(block => (block.include === undefined) || block.include())
      const numBlocks = category.contents.length
      if (numBlocks && (propNames.size > 12)) {
        for (let i = 0, end = numBlocks; i < end; i++) {
          // Add a separator block in between each actual block, to shrink space between them from default 24px
          category.contents.splice(2 * i, 0, { kind: 'sep', gap: 12 })
        }
      }
    }
  }
  blockCategories = blockCategories.filter(category => ((category.include === undefined) || category.include()) && ((category.contents === undefined) || (category.contents.length > 0)))

  for (const category of fullBlockCategories) {
    if (category.contents) {
      // Hide irrelevant, non-fully-included blocks from the code-to-blocks generator
      category.contents = category.contents.filter(block => (block.includeCodeToBlocks === undefined) || block.includeCodeToBlocks())
    }
  }

  const toolbox = {
    kind: 'categoryToolbox',
    contents: blockCategories,
    fullContents: fullBlockCategories,
  }

  return toolbox
}

const createBlock = function ({ owner, prop, generator, codeLanguage, codeFormat, include, level, superBasicLevels }) {
  const propName = prop.name ? prop.name.replace(/"/g, '') : undefined
  const returnsValue = (prop.returns != null) || (prop.userShouldCaptureReturn != null) || (!['function', 'snippet'].includes(prop.type))
  const name = `${owner}_${propName}`
  let args = prop.args || []
  if (superBasicLevels?.includes(level?.get('slug')) && (['moveDown', 'moveLeft', 'moveRight', 'moveUp'].includes(propName))) {
    // Don't include steps argument yet
    args = []
  }

  generator.forBlock[name] = function (block) {
    const parts = []
    if (propName && ['this', 'self', 'hero'].includes(prop.owner)) {
      if (level?.get('product') === 'codecombat-junior') {
        parts.push(propName) // Functional
      } else {
        parts.push(`hero.${propName}`) // Object-oriented
      }
    } else if (prop.type === 'function' || (prop.type === 'snippet' && args.length)) {
      parts.push(propName.replace(/\(.*/, ''))
    } else if (propName) {
      parts.push(propName)
    } else {
      parts.push(owner)
    }

    if (prop.type === 'function' || (prop.type === 'snippet' && args.length)) {
      parts.push('(')
      Object.keys(args).forEach((idx) => {
        if (idx > 0) parts.push(', ')
        const arg = args[idx]
        // let code = generator.valueToCode(block, arg.name, generator.ORDER_ATOMIC)
        let code = generator.valueToCode(block, arg.name, generator.ORDER_CONDITIONAL)
        if (!code && arg.name === 'to') {
          code = `'${block.getFieldValue(arg.name)}'`
        }
        if (!code && ['steps', 'squares'].includes(arg.name)) {
          code = `${block.getFieldValue(arg.name)}`
        }
        if (!code && arg.default) {
          if (/move(Up|Left|Right|Down)/.test(propName)) {
            // Don't add the default value
          } else {
            code = arg.default
          }
        }
        switch (codeLanguage) {
          case 'javascript':
            parts.push(code ?? `undefined /* ${arg.name} */`)
            break
          case 'python':
            parts.push(code ?? 'None')
            break
          case 'lua':
            parts.push(code ?? 'nil')
            break
        }
      })
      parts.push(')')
    }

    switch (codeLanguage) {
      case 'javascript':
        if (!returnsValue) parts.push(';\n')
        break
      case 'python':
      case 'lua':
        if (!returnsValue) parts.push('\n')
        break
    }

    return returnsValue ? [parts.join(''), generator.ORDER_ATOMIC] : parts.join('')
  }

  // CodeCombat Junior doesn't label arguments. (Should we label them for CodeCombat?)
  const blockMessage = level?.get('product') === 'codecombat-junior'
    ? `${(propName || owner).replace(/\(.*/, '')} ` + args.map((a, v) => `%${v + 1}`).join(' ')
    : `${(propName || owner).replace(/\(.*/, '')} ` + args.map((a, v) => `${a.name}: %${v + 1}`).join(' ')
  const setup = {
    message0: blockMessage,
    args0: args.map(a => ({
      type: 'input_value',
      name: a.name
    })),
    colour: returnsValue ? 350 : 240,
    tooltip: prop.description || '',
    docFormatter: prop.docFormatter,
    type: prop.type,
    inputsInline: args.length <= 2,
  }

  if (codeFormat === 'blocks-icons' && setup.message0.startsWith('go ')) {
    // Use an image instead of text
    setup.message0 = setup.message0.replace(/go %1 %2/, '%1%2 %3') // With steps
    setup.message0 = setup.message0.replace(/go %1/, '%1%2') // Without steps
    setup.args0.unshift({
      type: 'field_image',
      src: '/images/level/blocks/block-go.png',
      width: 36,
      height: 36,
      alt: 'go'
    })
  }

  if (codeFormat === 'blocks-icons' && setup.message0.startsWith('hit ')) {
    // Use an image instead of text
    setup.message0 = setup.message0.replace(/hit %1 %2/, '%1%2 %3') // With times
    setup.message0 = setup.message0.replace(/hit %1/, '%1%2') // Without times
    setup.args0.unshift({
      type: 'field_image',
      src: '/images/level/blocks/block-hit.png',
      width: 36,
      height: 36,
      alt: 'hit'
    })
  }

  if (codeFormat === 'blocks-icons' && setup.message0.startsWith('zap ')) {
    // Use an image instead of text
    setup.message0 = setup.message0.replace(/zap %1 %2/, '%1%2 %3') // With times
    setup.message0 = setup.message0.replace(/zap %1/, '%1%2') // Without times
    setup.args0.unshift({
      type: 'field_image',
      src: '/images/level/blocks/block-zap.png',
      width: 36,
      height: 36,
      alt: 'zap'
    })
  }

  if (codeFormat === 'blocks-icons' && setup.message0.startsWith('spin ')) {
    // Use an image instead of text
    setup.message0 = setup.message0.replace(/spin %1/, '%1 %2') // With times
    setup.message0 = setup.message0.replace(/spin/, '%1') // Without times
    setup.args0.unshift({
      type: 'field_image',
      src: '/images/level/blocks/block-spin.png',
      width: 36,
      height: 36,
      alt: 'spin'
    })
  }

  if (codeFormat === 'blocks-icons' && setup.message0.startsWith('look ')) {
    // Use an image instead of text
    setup.message0 = setup.message0.replace(/look %1 %2/, '%1%2 %3') // With squares
    setup.message0 = setup.message0.replace(/look %1/, '%1%2') // Without squares
    setup.args0.unshift({
      type: 'field_image',
      src: '/images/level/blocks/block-look.png',
      width: 36,
      height: 36,
      alt: 'look'
    })
  }

  // Replace a `to` directional argument with a dropdown (field, not input)
  if (args[0]?.name === 'to' && args[0].type === 'string') {
    const dropdownArg = setup.args0[codeFormat === 'blocks-icons' ? 1 : 0]
    dropdownArg.type = 'field_dropdown'
    if (codeFormat === 'blocks-icons') {
      dropdownArg.options = [
        [{ src: '/images/level/blocks/block-up.png', width: 36, height: 36 }, 'up'],
        [{ src: '/images/level/blocks/block-down.png', width: 36, height: 36 }, 'down'],
        [{ src: '/images/level/blocks/block-left.png', width: 36, height: 36 }, 'left'],
        [{ src: '/images/level/blocks/block-right.png', width: 36, height: 36 }, 'right']
      ]
    } else {
      dropdownArg.options = [
        ['up', 'up'],
        ['down', 'down'],
        ['left', 'left'],
        ['right', 'right']
      ]
    }
    dropdownArg.default = args[0].default
    if (_.isString(dropdownArg.default)) {
      dropdownArg.default = dropdownArg.default.replace(/['"]/g, '')
    }
  }

  // Replace a `steps` or `squares` numerical argument with a dropdown (field, not input)
  if (['steps', 'squares'].includes(args[1]?.name) && args[1].type === 'number') {
    const dropdownArg = setup.args0[codeFormat === 'blocks-icons' ? 2 : 1]
    dropdownArg.type = 'field_dropdown'
    dropdownArg.options = [
      ['1', '1'],
      ['2', '2'],
      ['3', '3'],
      ['4', '4'],
      ['5', '5'],
      ['6', '6'],
    ]
    dropdownArg.default = args[1].default
    if (_.isString(dropdownArg.default)) {
      dropdownArg.default = dropdownArg.default.replace(/['"]/g, '')
    }
  }

  if (returnsValue) {
    setup.output = null
  } else {
    setup.previousStatement = null
    setup.nextStatement = null
  }

  // console.log 'Defining new block', name, setup
  const blockInitializer = {
    init () {
      this.jsonInit(setup)
      for (const [index, arg] of setup.args0.entries()) {
        if (arg?.type === 'field_dropdown') {
          const defaultValue = arg.default
          if (defaultValue) {
            const field = _.find(this.inputList[0].fieldRow, f => f.name === arg.name)
            if (field) {
              field.setValue('' + defaultValue)
            }
          }
        }
      }
      this.docFormatter = setup.docFormatter
      this.tooltipImg = setup.tooltipImg
    },
    setupInfo: setup
  }
  Blockly.Blocks[name] = blockInitializer
  const blockDefinition = {
    kind: 'block',
    type: `${name.replace(/\"/g, '\'')}` // eslint-disable-line no-useless-escape
  }
  if (include != null) { blockDefinition.include = include }
  for (const arg of args) {
    if (arg.default != null) {
      if (blockDefinition.inputs == null) { blockDefinition.inputs = {} }
      const type = { string: 'text', number: 'math_number', int: 'math_number', boolean: 'logic_boolean' }[arg.type] || 'text' // TODO: more types
      const field = { string: 'TEXT', number: 'NUM', int: 'NUM', boolean: 'BOOL' }[arg.type]
      if (!type || !field) { continue }
      let defaultValue = arg.default
      if (_.isString(defaultValue)) {
        defaultValue = defaultValue.replace(/['"]/g, '')
      }
      if (arg.name === 'to' && arg.type === 'string') {
        // We're making this into a field_dropdown, not an input
        continue
      }
      if (['steps', 'squares'].includes(arg.name) && arg.type === 'number') {
        // We're making this into a field_dropdown, not an input
        continue
      }
      blockDefinition.inputs[arg.name] = { shadow: { type, fields: { [field]: defaultValue } } }
    }
  }
  return blockDefinition
}

const customTooltip = function (div, element) {
  let tip
  const container = document.createElement('div')
  if (element.docFormatter) {
    tip = element.docFormatter.formatPopover()
    container.innerHTML = tip
  } else {
    tip = Blockly.Tooltip.getTooltipOfObject(element)
    container.textContent = tip
  }
  return div.appendChild(container)
}

let initializedTooltips = false
module.exports.initializeBlocklyTooltips = function () {
  if (initializedTooltips) { return }
  initializedTooltips = true
  return Blockly.Tooltip.setCustomTooltip(customTooltip)
}

let registeredTheme = false
module.exports.registerBlocklyTheme = function () {
  if (registeredTheme) { return }
  registeredTheme = true
  return Blockly.Theme.defineTheme('coco-dark', {
    base: Blockly.Themes.Classic,
    componentStyles: {
      // workspaceBackgroundColour: '#1e1e1e'
      toolboxBackgroundColour: 'blackBackground',
      toolboxForegroundColour: '#fff',
      flyoutBackgroundColour: '#252526',
      flyoutForegroundColour: '#ccc',
      flyoutOpacity: 1,
      scrollbarColour: '#797979',
      insertionMarkerColour: '#fff',
      insertionMarkerOpacity: 0.3,
      scrollbarOpacity: 0.4,
      cursorColour: '#d0d0d0',
      blackBackground: '#333'
    },
    fontStyle: {
      family: 'Menlo, Monaco, Consolas, "Courier New", monospace'
    }
  }
  )
}

let initializedLanguage = false
module.exports.initializeBlocklyLanguage = function () {
  if (initializedLanguage) { return }
  return // TODO: need to fix webpack loading first
  // eslint-disable-function
  initializedLanguage = true
  const language = me.get('preferredLanguage', true).toLowerCase()
  const languageParts = language.split('-')
  while (languageParts.length) {
    try {
      const localePath = `blockly/msg/${languageParts.join('-')}`
      console.log('trying to load', localePath)
      // TODO: fix this up with proper webpackery, maybe like https://github.com/codecombat/codecombat/blob/master/app/locale/locale.coffee#L78-L102
      // blocklyLocale = require(localePath)  // doesn't work
      // blocklyLocale = require(`blockly/msg/${languageParts.join('-')}`)  // works but throws a ton of errors
      Blockly.setLocale(blocklyLocale)
      break
    } catch (e) {
      console.log(e)
      languageParts.pop()
    }
  }
}

module.exports.createBlocklyOptions = function ({ toolbox, renderer, codeLanguage, codeFormat, product }) {
  module.exports.initializeBlocklyLanguage()
  return {
    toolbox,
    toolboxPosition: 'end',
    theme: 'coco-dark',
    plugins: {
      toolbox: ContinuousToolbox,
      flyoutsVerticalToolbox: ContinuousFlyout,
      metricsManager: ContinuousMetrics
    },
    sounds: me.get('volume') > 0,
    // Renderer choices: 'geras': default, 'thrasos': more modern take on geras, 'zelos': Scratch-like
    // renderer: 'zelos',
    // renderer: 'thrasos',
    renderer: renderer || ($(window).innerHeight() > 500 && product === 'codecombat-junior' ? 'zelos' : 'thrasos'),
    zoom: {
      // Hide so that we don't mess with width of toolbox
      controls: false,
      startScale: 1,
      minScale: 0.5,
      maxScale: 1.5,
    },
    trashcan: false,
    // oneBasedIndex: codeLanguage === 'lua' // TODO: Need to test. Default is true.
    move: {
      scrollbars: true,
      drag: true,
      wheel: true
    },
    // No grid. Thought we could maybe make fake "lines", but block heights are too unpredictable.
    // grid: {
    //   spacing: 48,
    //   length: 48,
    //   colour: '#000',
    //   snap: true
    // },
    collapse: codeFormat !== 'blocks-icons', // Don't let blocks be collapsed in icon mode
    disable: true, // Do let blocks be disabled
  }
}

module.exports.getBlocklyGenerator = function (codeLanguage) {
  switch (codeLanguage) {
    case 'python': return (require('blockly/python')).pythonGenerator
    case 'lua': return (require('blockly/lua')).luaGenerator
    case 'javascript': return (require('blockly/javascript')).javascriptGenerator
    default: return (require('blockly/javascript')).javascriptGenerator
  }
}

let initializedCopyPastePlugin = false
module.exports.initializeBlocklyPlugins = function (blockly) {
  if (!initializedCopyPastePlugin) {
    initializedCopyPastePlugin = true
    // https://google.github.io/blockly-samples/plugins/cross-tab-copy-paste/README
    const crossTabCopyPastePlugin = new CrossTabCopyPaste()
    crossTabCopyPastePlugin.init({ contextMenu: true, shortcut: true }, err => console.log('CrossTabCopyPastePlugin paste error', err))
    // optional: Remove the duplication command from Blockly's context menu
    // Blockly.ContextMenuRegistry.registry.unregister('blockDuplicate')
    // optional: Change the position of the items added to the context menu
    Blockly.ContextMenuRegistry.registry.getItem('blockCopyToStorage').weight = 0
    Blockly.ContextMenuRegistry.registry.getItem('blockPasteFromStorage').weight = 0
  }
}

// zoomToFit = new ZoomToFitControl blockly
// zoomToFit.init()

module.exports.getBlocklySource = function (blockly, { codeLanguage, product }) {
  if (!blockly) { return }
  const blocklyState = Blockly.serialization.workspaces.save(blockly)
  const generator = module.exports.getBlocklyGenerator(codeLanguage)
  let blocklySourceRaw = generator.workspaceToCode(blockly)
  blocklySourceRaw = module.exports.rewriteBlocklyCode(blocklySourceRaw, { codeLanguage, product })
  let blocklySource
  if (product === 'codecombat-junior') {
    blocklySource = condenseNewlines(blocklySourceRaw)
  } else {
    blocklySource = blocklySourceRaw
  }
  const commentStart = utils.commentStarts[codeLanguage] || '//'
  // console.log "Blockly state", blocklyState
  // console.log "Blockly source", blocklySource
  const combined = `${commentStart}BLOCKLY| ${JSON.stringify(blocklyState)}\n\n${blocklySource}`
  return { blocklyState, blocklySource, combined, blocklySourceRaw }
}

module.exports.loadBlocklyState = function (blocklyState, blockly, tries) {
  if (tries == null) { tries = 0 }
  if (tries > 10) { return false }
  if (!blocklyState?.blocks) { return false }
  if (!blocklyState.blocks.blocks) { blocklyState.blocks.blocks = [] }
  const oldBlocklyState = Blockly.serialization.workspaces.save(blockly)
  try {
    // console.log('Need to load', blocklyState, 'into', blockly, 'comparing to', oldBlocklyState)
    const mergeProgress = {}
    for (let i = 0; i < blocklyState?.blocks?.blocks?.length; ++i) {
      mergeBlocklyStates(oldBlocklyState?.blocks?.blocks?.[i], blocklyState.blocks.blocks[i], mergeProgress)
    }
    Blockly.serialization.workspaces.load(blocklyState, blockly)
    if (mergeProgress.unmatched) {
      blockly.cleanUp()
    }
    return true
  } catch (err) {
    // Example error: Invalid block definition for type: Esper.str_undefined
    // TODO: For some reason, this requires a page reload after filtering before Blockly code starts editing again. Not sure where problem is.
    const blockType = err.message.match(/Invalid block definition for type: (.*)/)?.[1]
    if (blockType) {
      blocklyState = filterBlocklyState(blocklyState, blockType)
      return module.exports.loadBlocklyState(blocklyState, blockly, tries + 1)
    } else {
      console.error('Error loading Blockly state', err)
      return false
    }
  }
}

const blockHeight = 25
function mergeBlocklyStates (oldState, newState, mergeProgress) {
  if (!newState) {
    return
  }
  if (!oldState) {
    // We will make up a height, but it's probably wrong, so we'll automatically clean up workspace at the end.
    mergeProgress.unmatched = true
    // This logic will get y-ordering right, at least.
    if (mergeProgress.lastX === undefined) {
      mergeProgress.lastX = 20
      mergeProgress.lastY = 20
      mergeProgress.blocksSinceLastYSet = -2
    }
    newState.x = mergeProgress.lastX
    newState.y = mergeProgress.lastY + blockHeight * (mergeProgress.blocksSinceLastYSet + 2)
    mergeProgress.blocksSinceLastYSet += countBlocks(newState) + 2
    return
  }
  if (oldState.type === newState.type) {
    // TODO: check more properties for equality.
    // For example, let's say we reordered blocks in Blockly that have same type but different inputs, like hero.say("hello") and hero.say("world").
    // This current logic will not realize the blocks have changed, and will effectively undo the order change when edited in code.
    // console.log('merging', oldState.type, oldState.id, oldState.x, oldState.y, _.cloneDeep(oldState), _.cloneDeep(newState))
    newState.id = oldState.id
    if (oldState.x !== undefined) {
      newState.x = mergeProgress.lastX = oldState.x
      newState.y = mergeProgress.lastY = oldState.y
      mergeProgress.blocksSinceLastYSet = 0
    } else {
      ++mergeProgress.blocksSinceLastYSet
    }
    if (newState.next) {
      mergeBlocklyStates(oldState.next?.block, newState.next.block, mergeProgress)
    }
  }
}

function countBlocks (newState) {
  // TODO: this should probably count nested blocks, arguments, also account for taller blocks. But, not important with auto blockly.cleanUp() function.
  let count = 0
  while (newState?.next) {
    ++count
    newState = newState.next.block
  }
  return count
}

const filterBlocklyState = function (blocklyState, blockType) {
  // Stubs out all blocks of the given type from the blockly state. Useful for not throwing away all code just because a block definition is missing.
  console.log('Trying to remove', blockType, 'from blockly state', blocklyState, 'with', blocklyState?.blocks?.blocks?.length ?? 0, 'blocks')
  // console.log 'Trying to remove', blockType, 'from blockly state', _.cloneDeep(blocklyState), 'with', blocklyState.blocks?.blocks?.length, 'blocks'  # debugging
  // Recursively walk through all properties of the blockly state, and transform the ones with type: blockType to be comment blocks
  const transformBlock = function (parent, key, value) {
    if ((value != null ? value.type : undefined) === blockType) {
      // console.log 'Found block of type', blockType, 'at', key, 'in', _.cloneDeep parent
      // console.log 'Replacing with comment block'
      // console.log 'Parent before', _.cloneDeep parent
      parent[key] = { type: 'text', x: value.x, y: value.y, id: value.id, fields: { TEXT: `Missing block ${blockType}` } }
      // console.log 'Parent after', _.cloneDeep parent
      return parent[key]
    } else if (_.isObject(value)) {
      return _.each(value, (v, k) => transformBlock(value, k, v))
    }
  }
  transformBlock(null, 'blocks', blocklyState.blocks.blocks)
  return blocklyState
}

module.exports.isEqualBlocklyState = function (state1, state2) {
  const keysToIgnore = ['x', 'y', 'id', 'start', 'end', 'languageVersion']
  const keysToIgnoreWhenEmpty = ['variables', 'inputs']

  function isEmptyOrUndefined (value) {
    return value === undefined || value === null || (_.isArray(value) && value.length === 0) || (_.isObject(value) && _.size(value) === 0)
  }

  function isEqualIgnoringSomeKeys (obj1, obj2) {
    // If both are the same object or both are null/undefined, they are equal
    if (obj1 === obj2) return true

    // If either is not an object (and they are not equal), they are not equal
    if (!_.isObject(obj1) || !_.isObject(obj2)) return false

    // Get keys from both objects
    const keys1 = _.without(Object.keys(obj1), ...keysToIgnore)
    const keys2 = _.without(Object.keys(obj2), ...keysToIgnore)

    for (const key of _.union(keys1, keys2)) {
      // Treat as equal if the key should be ignored when empty and both values are empty
      if (keysToIgnoreWhenEmpty.includes(key)) {
        if (isEmptyOrUndefined(obj1[key]) && isEmptyOrUndefined(obj2[key])) {
          continue
        }
      }

      // If both values are objects, compare recursively
      if (_.isObject(obj1[key]) && _.isObject(obj2[key])) {
        if (!isEqualIgnoringSomeKeys(obj1[key], obj2[key])) return false
      }
      // For non-object values, use Lodash's isEqual for comparison
      else {
        if (!_.isEqual(obj1[key], obj2[key])) return false
      }
    }

    return true
  }

  return isEqualIgnoringSomeKeys(state1, state2)
}

function blockSubtreeIncludesBlockType (block, type) {
  if (block?.type === type) { return true }
  if (!block?.next) { return false }
  return blockSubtreeIncludesBlockType(block.next, type)
}

module.exports.blocklyStateIncludesBlockType = function (state, type) {
  for (const block of state?.blocks?.blocks) {
    if (blockSubtreeIncludesBlockType(block, type)) {
      return true
    }
  }
  return false
}

module.exports.rewriteBlocklyCode = function (code, { codeLanguage, product }) {
  code = code.replace(/☃/gm, '') // Undo our unicode snowman whitespace trimmer remover
  codeLanguage = codeLanguage || 'javascript'
  switch (codeLanguage) {
    case 'javascript':
      return rewriteBlocklyJS(code, { product })
    case 'python':
      return rewriteBlocklyPython(code, { product })
    case 'lua':
      return rewriteBlocklyLua(code, { product })
    default:
      throw new Error(`Unknown code language ${codeLanguage}`)
  }
}

function rewriteBlocklyJS (code, { product }) {
  // Replace var greeting;\n\ngreeting = 'Hello'; with var greeting = 'Hello';
  code = code.replace(/^var (\S+,? ?)+\n*/, '')
  const found = []
  code = code.replace(/^(\s*)([a-zA-Z0-9_-]+) = /mg, (m, s, n) => {
    if (found.indexOf(n) !== -1) return m
    found.push(n)
    return s + 'var ' + n + ' = '
  })

  // Replace count, count2, etc. repeat variables with i, j, etc.
  code = code.replace(/\bcount(\d*)\b(\+\+)?/g, (match, num, increment) => {
    const index = num ? parseInt(num) : 1
    const letter = String.fromCharCode(105 + index - 1) // 105 is ASCII code for 'i'
    return increment ? `${letter}${increment}` : letter
  })

  // Replace var with let
  code = code.replace(/\bvar\b/g, 'let')

  return code.trim()
}

function rewriteBlocklyPython (code, { product }) {
  let oldCode
  do {
    oldCode = code
    code = code.replace(/^[a-zA-Z0-9_-s]+ = None\n/, '')
  } while (code !== oldCode)

  // Replace count, count2, etc. repeat variables with i, j, etc. in Python code
  code = code.replace(/\bcount(\d*)\b/g, (match, num) => {
    const index = num ? parseInt(num) : 1
    const letter = String.fromCharCode(105 + index - 1) // 105 is ASCII code for 'i'
    return letter
  })

  return code.trim()
}

function rewriteBlocklyLua (code, { product }) {
  return code
}

function condenseNewlines (code) {
  // Replace multiple newlines, possibly with whitespace in the middle, with single newlines
  // Only do this in between lines of code, not comments
  return code.replace(/([^\n])\n[ \t]*\n([^\n])/g, '$1\n$2')
}

function findLastBlockWithNextConnection (block) {
  let lastBlockWithNextConnection
  if (block.nextConnection) {
    lastBlockWithNextConnection = block
  }
  for (const child of block.getChildren(true)) {
    lastBlockWithNextConnection = findLastBlockWithNextConnection(child) || lastBlockWithNextConnection
  }
  return lastBlockWithNextConnection
}

module.exports.createBlockById = function ({ workspace, id, codeLanguage }) {
  const flyoutBlock = workspace.getToolbox()?.getFlyout()?.getWorkspace()?.getBlockById(id)
  if (!flyoutBlock) return null
  const topBlocks = workspace.getTopBlocks(true)
  const newWorkspaceBlock = workspace.getToolbox()?.getFlyout()?.createBlock(flyoutBlock)
  if (!newWorkspaceBlock) return null
  let lastBlock
  for (const block of topBlocks) {
    lastBlock = findLastBlockWithNextConnection(block) || lastBlock
  }
  if (lastBlock) {
    const parentConnection = lastBlock.nextConnection
    const childConnection = newWorkspaceBlock.previousConnection
    if (parentConnection && childConnection) {
      parentConnection.connect(childConnection)
      return newWorkspaceBlock
    }
  }
  newWorkspaceBlock.moveBy(0, 1000, 'Could not automatically connect. Putting this all the way down so that it goes in the right order when we clean up.')
  workspace.cleanUp()
  return newWorkspaceBlock
}

module.exports.blocklyMutationEvents = [Blockly.Events.CHANGE, Blockly.Events.CREATE, Blockly.Events.DELETE, Blockly.Events.BLOCK_CHANGE, Blockly.Events.BLOCK_CREATE, Blockly.Events.BLOCK_DELETE, Blockly.Events.BLOCK_DRAG, Blockly.Events.BLOCK_FIELD_INTERMEDIATE_CHANGE, Blockly.Events.BLOCK_MOVE, Blockly.Events.VAR_CREATE, Blockly.Events.VAR_DELETE, Blockly.Events.VAR_RENAME]
module.exports.blocklyFinishedMutationEvents = _.without(module.exports.blocklyMutationEvents, Blockly.Events.CREATE, Blockly.Events.BLOCK_CREATE, Blockly.Events.BLOCK_DRAG, Blockly.Events.VAR_CREATE, Blockly.Events.VAR_DELETE, Blockly.Events.VAR_RENAME)
