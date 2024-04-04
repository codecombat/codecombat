const Blockly = require('blockly')
const { javascriptGenerator } = require('blockly/javascript')

function fuzzyMatch (a, b) {
  if (a.type !== b.type) return false
  switch (a.type) {
    case 'Identifier':
      return a.name === b.name
    case 'CallExpression':
      if (!fuzzyMatch(a.callee, b.callee)) return false
      return true
    case 'MemberExpression':
      return fuzzyMatch(a.object, b.object) && fuzzyMatch(a.property, b.property) && a.computed === b.computed
    case 'NumericLiteral':
    case 'StringLiteral':
    case 'BooleanLiteral':
      return true
    case 'ArrayExpression':
      return (a.elements.length === 0) === (b.elements.length === 0)
    case 'BreakStatement':
    case 'ContinueStatement':
      return true
    case 'WhileStatement':
    case 'ForStatement':
    case 'ConditionalExpression':
      return true
    case 'IfStatement':
      return true
    default:
      throw new Error(`Don't know how to fuzzy compare ${a.type}`)
  }
}

function findOne (array, pred, why = 'Expected exactly one match') {
  const matches = array.filter(pred)
  if (matches.length === 1) {
    return matches[0]
  }
  if (matches.length > 1) {
    const nonSnippets = matches.filter(x => x[0].setupInfo?.type !== 'snippet')
    if (nonSnippets.length === 1) {
      // There's one main match and then some duplicative snippets, it's ok
      return nonSnippets[0]
    }
    if (nonSnippets.length === 0) {
      // There are multiple matching snippets; it's ok to just pick one
      return matches[0]
    }
    // There are multiple matching non-snippets; maybe this is bad and we should error out?
    console.log('Multiple block matches:', matches, '\nfrom possibilities:', array)
    throw new Error(why + ', found ' + matches.length)
  }
  if (matches.length === 0) {
    // There are no matches
    console.log('No block matches from possibilities:', array)
    throw new Error(why + ', found ' + matches.length)
  }
}
class Converters {
  static ConvertProgram (n, ctx) {
    return {
      blocks: convert(n.body, ctx)
    }
  }

  static ConvertVariableDeclaration (n, ctx) {
    const result = []
    for (const d of n.declarations) {
      ctx.scope[d.id.name] = { type: 'var' }

      if (!d.init) continue

      result.push({
        type: 'variables_set',
        fields: { VAR: { id: d.id.name } },
        inputs: {
          VALUE: { block: convert(d.init, { ...ctx, context: 'value' }) }
        }
      })
    }
    return result.length > 0 ? nextify(result, { ...ctx, nospace: true })[0] : null
  }

  static ConvertLiteral (n, ctx) {
    switch (typeof (n.value)) {
      case 'string':
        n.type = 'StringLiteral'
        return Converters.ConvertStringLiteral(n, ctx)
      case 'number':
        n.type = 'NumericLiteral'
        return Converters.ConvertNumericLiteral(n, ctx)
      case 'boolean':
        n.type = 'BooleanLiteral'
        return Converters.ConvertBooleanLiteral(n, ctx)
    }
  }

  static ConvertNumericLiteral (n, ctx) {
    const found = findOne(ctx.plan, x => fuzzyMatch(n, x[1]), 'Finding Numeric Literal')
    return {
      type: found[0].type,
      fields: { NUM: n.value }
    }
  }

  static ConvertStringLiteral (n, ctx) {
    const found = findOne(ctx.plan, x => fuzzyMatch(n, x[1]), 'Finding String Literal')
    return {
      type: found[0].type,
      fields: { TEXT: n.value }
    }
  }

  static ConvertBooleanLiteral (n, ctx) {
    const found = findOne(ctx.plan, x => fuzzyMatch(n, x[1]), 'Finding Boolean Literal')
    return {
      type: found[0].type,
      fields: { BOOL: n.value ? 'TRUE' : 'FALSE' }
    }
  }

  static ConvertBlockStatement (n, ctx) {
    return convert(n.body, { ...ctx, context: 'statement' })
  }

  static ConvertExpressionStatement (n, ctx) {
    return convert(n.expression, ctx, { ...ctx, context: 'statement' })
  }

  static ConvertBreakStatement (n, ctx) {
    return findOne(ctx.plan, x => fuzzyMatch(n, x[1]), 'Can\'t find the break statement')[0]
  }

  static ConvertContinueStatement (n, ctx) {
    return findOne(ctx.plan, x => fuzzyMatch(n, x[1]), 'Can\'t find the continue statement')[0]
  }

  static ConvertArrayExpression (n, ctx) {
    const found = findOne(ctx.plan, x => fuzzyMatch(n, x[1]), 'Can\'t find the array expression')
    const o = {
      type: found[0].type,
      extraState: { itemCount: n.elements.length },
      inputs: {}
    }
    for (let i = 0; i < n.elements.length; ++i) {
      o.inputs['ADD' + i] = { block: convert(n.elements[i], { ...ctx, context: 'value' }) }
    }
    return o
  }

  static ConvertWhileStatement (n, ctx) {
    const found = findOne(ctx.plan, x => fuzzyMatch(n, x[1]), 'Can\'t find the while statement')
    const body = convert(n.body, { ...ctx, nospace: true, context: 'statement' })
    const o = {
      type: found[0].type,
      inputs: {
        BOOL: { block: convert(n.test, { ...ctx, context: 'value' }) }
      }
    }
    if (body && body.length > 0) o.inputs.DO = { block: body[0] }

    return o
  }

  static ConvertConditionalExpression (n, ctx) {
    const found = findOne(ctx.plan, x => fuzzyMatch(n, x[1]), 'Can\'t find the ternary expression')
    const yes = convert(n.consequent, { ...ctx, nospace: true, context: 'value' })
    const no = convert(n.alternate, { ...ctx, nospace: true, context: 'value' })

    const o = {
      type: found[0].type,
      inputs: {
        IF: { block: convert(n.test, ctx) }
      }
    }

    if (yes) o.inputs.THEN = { block: yes }
    if (no) o.inputs.ELSE = { block: no }

    return o
  }

  static ConvertEmptyStatement (n, ctx) {
    return null
  }

  static ConvertForStatement (n, ctx) {
    const found = findOne(ctx.plan, x => fuzzyMatch(n, x[1]), 'Can\'t find the for statement')
    convert(n.init, { ...ctx, nospace: true })
    const body = convert(n.body, { ...ctx, nospace: true, context: 'statement' })

    // Only handles most basic cases for now, like standard for (let i = 0; i < 3; i++)
    const start = n.init?.declarations?.[0]?.init?.value ?? 0
    const end = n.test?.right?.value ?? 1
    const times = end - start
    // For Junior, we have simplified dropdown block if the range is in 1-7
    const type = times >= 1 && times <= 7 && _.find(ctx.plan, p => p[0].type === 'controls_repeat_dropdown') ? 'controls_repeat_dropdown' : found[0].type
    let o
    if (type === 'controls_repeat_dropdown') {
      // Change input to field
      o = { type, inputs: {}, fields: { TIMES: '' + times } }
    } else {
      // TODO: figure out how to always include controls_repeat_ext so that we can handle if the number is outside our target range
      o = { type, inputs: { TIMES: { block: convert(n.test.right, ctx) } } }
    }

    if (body) o.inputs.DO = { block: body[0] }
    return o
  }

  static ConvertForOfStatement (n, ctx) {
    ctx.scope[n.left.name] = { type: 'var' }
    const body = convert(n.body, { ...ctx, nospace: true, context: 'statement' })
    let o
    if (n.right?.type === 'CallExpression' && n.right.callee?.name === 'range' && n.right.arguments?.length && (!n.right.arguments[2] || n.right.arguments[2].value === 1)) {
      try {
        // Use controls_repeat_ext block instead of a controls_forEach block for Python ranges that are just repeating N times
        let start, end, endNode
        if (n.right.arguments.length > 1) {
          start = n.right.arguments[0].value
          end = n.right.arguments[1].value
          endNode = n.right.arguments[1]
        } else {
          start = 0
          end = n.right.arguments[0].value
          endNode = n.right.arguments[0]
        }
        const times = end - start
        // For Junior, we have simplified dropdown block if the range is in 1-7
        const type = times >= 1 && times <= 7 && _.find(ctx.plan, p => p[0].type === 'controls_repeat_dropdown') ? 'controls_repeat_dropdown' : 'controls_repeat_ext'
        if (type === 'controls_repeat_ext' && !_.find(ctx.plan, p => p[0].type === 'controls_repeat_ext')) {
          // TODO: figure out how to include both block definitions without breaking code-to-blocks finding right one in its planning
          throw new Error('controls_repeat_ext block not available for loop with range', start, 'to', end)
        }
        if (type === 'controls_repeat_dropdown') {
          // Change input to field
          o = { type, inputs: {}, fields: { TIMES: '' + times } }
        } else {
          const fakeTimesNode = _.cloneDeep(endNode)
          fakeTimesNode.raw = '' + times
          fakeTimesNode.value = times
          const fakeBlock = convert(fakeTimesNode, ctx)
          o = { type, inputs: { TIMES: { block: fakeBlock } } }
        }
      } catch (err) {
        console.error("Couldn't convert for-in range to simple repeat block:", n, err)
      }
    }
    if (!o) {
      o = {
        // type: 'controls_untyped_for_each',
        type: 'controls_forEach',
        fields: {
          VAR: { id: n.left.name }
        },
        inputs: {
          LIST: { block: convert(n.right, { ...ctx, context: 'value' }) }
        }
      }
    }

    if (body) o.inputs.DO = { block: body[0] }
    return o
  }

  static ConvertIfStatement (n, ctx) {
    // TODO: ELSE, ELSEIF
    // console.log('IF', n)
    const conq = convert(n.consequent, { ...ctx, context: 'statement', nospace: true })
    const o = {
      type: 'controls_if',
      extraState: {},
      inputs: {
        IF0: { block: convert(n.test, { ...ctx, context: 'value' }) }
      }
    }

    if (conq) o.inputs.DO0 = { block: conq[0] }

    let N = 0
    let alt = n.alternate

    while (alt && (alt.type === 'IfStatement' || alt.type === 'BlockStatement')) {
      if (alt.type === 'BlockStatement') {
        if (alt.body.length !== 1 || alt.body[0].type !== 'IfStatement') break
        alt = alt.body[0]
        continue
      }
      ++N
      o.extraState.elseIfCount = N
      o.inputs[`IF${N}`] = { block: convert(alt.test, ctx, { ...ctx, context: 'value' }) }
      o.inputs[`DO${N}`] = { block: convert(alt.consequent, ctx, { ...ctx, context: 'statement', nospace: true })[0] }
      alt = alt.alternate
    }

    if (alt) {
      o.inputs.ELSE = { block: convert(alt, { ...ctx, context: 'statement', nospace: true })[0] }
      o.extraState.hasElse = true
    }
    return o
  }

  static ConvertAssignmentExpression (n, ctx) {
    if (n.operator !== '=') throw new Error(`Weird assigment operator ${n.operator}`)
    if (n.left.type !== 'Identifier') throw new Error('Can only assign to variables')

    return {
      type: 'variables_set',
      fields: { VAR: { id: n.left.name } },
      inputs: {
        VALUE: { block: convert(n.right, { ...ctx, context: 'value' }) }
      }
    }
  }

  static ConvertBinaryExpression (n, ctx) {
    const [type, op] = ({
      '+': ['math_or_string_arithmetic', 'ADD'],
      '-': ['math_or_string_arithmetic', 'MINUS'],
      '*': ['math_or_string_arithmetic', 'MULTIPLY'],
      '/': ['math_or_string_arithmetic', 'DIVIDE'],
      '**': ['math_or_string_arithmetic', 'POWER'],

      '&&': ['logic_operation', 'AND'],
      '||': ['logic_operation', 'OR'],

      '>': ['logic_compare', 'GT'],
      '<': ['logic_compare', 'LT'],
      '>=': ['logic_compare', 'GTE'],
      '<=': ['logic_compare', 'LTE'],
      '==': ['logic_compare', 'EQ'],
      '!=': ['logic_compare', 'NEQ'],

      '===': ['logic_compare', 'EQ'],
      '!==': ['logic_compare', 'NEQ']

    })[n.operator]
    return {
      type,
      fields: {
        OP: op
      },
      inputs: {
        A: { block: convert(n.left, ctx) },
        B: { block: convert(n.right, ctx) }
      }
    }
  }

  static ConvertLogicalExpression (n, ctx) {
    return Converters.ConvertBinaryExpression(n, ctx)
  }

  static ConvertReturnStatement (n, ctx) {
    const o = {
      type: 'procedures_return'
    }

    if (n.argument) {
      o.inputs = { VALUE: { block: convert(n.argument, { ...ctx, context: 'value' }) } }
    }

    return o
  }

  static ConvertCallExpression (n, ctx) {
    if (n.callee.type === 'Identifier') {
      // console.log('CALL', n, ctx.scope)

      if (n.callee.name === '__comment__') {
        return {
          type: 'comment',
          fields: {
            COMMENT: n.arguments[0].value.trim()
          }
        }
      }

      if (n.callee.name === '__arrow__') {
        return {
          type: 'entry_point',
          fields: {
          }
        }
      }

      if (n.callee.name === '__donothing__') {
        return null
      }

      if (ctx.scope[n.callee.name] && ctx.scope[n.callee.name].type === 'fx') {
        const inputs = {}
        const extraState = { params: [] }
        for (let i = 0; i < n.arguments.length; ++i) {
          inputs[`ARG${i}`] = { block: convert(n.arguments[i], { ...ctx, context: 'value' }) }
        }
        for (const p of ctx.scope[n.callee.name].n.params) {
          extraState.params.push(p.name)
        }

        if (ctx.context === 'value') {
          return {
            type: 'procedures_callreturn',
            fields: {
              NAME: n.callee.name
            },
            inputs,
            extraState
          }
        } else {
          return {
            type: 'procedures_callnoreturn',
            fields: {
              NAME: n.callee.name
            },
            inputs,
            extraState
          }
        }
      }
    }

    if (n.callee.type === 'MemberExpression') {
      if (n.callee.object.type === 'Identifier' && ctx.scope[n.callee.object.name] && ctx.scope[n.callee.object.name].type === 'var') {
        if (n.callee.property.name === 'push' || n.callee.property.name === 'append') {
          const val = convert(n.arguments[0], { ...ctx, context: 'value' })
          const vari = convert(n.callee.object, { ...ctx, context: 'value' })
          return {
            type: 'lists_setIndex',
            fields: {
              MODE: 'INSERT',
              WHERE: 'LAST'
            },
            inputs: {
              LIST: { block: vari },
              TO: { block: val }
            }
          }
        }

        if (n.callee.property.name === 'pop') {
          const vari = convert(n.callee.object, { ...ctx, context: 'value' })
          return {
            type: 'lists_getIndex',
            extraState: { isStatement: ctx.context !== 'value' },
            fields: {
              MODE: ctx.context === 'value' ? 'GET_REMOVE' : 'REMOVE',
              WHERE: 'LAST'
            },
            inputs: {
              VALUE: { block: vari }
            }
          }
        }
      }
    }

    const found = findOne(ctx.plan, x => fuzzyMatch(n, x[1]), `Couldn't find match for ${JSON.stringify(n)}`)
    // console.log('CALL', ctx, found[0])

    const out = {
      type: found[0].type,
      inputs: {}
    }

    const args = n.arguments.map(x => convert(x, { ...ctx, context: 'value' }))
    if (found[0].inputs) {
      const inputs = Object.keys(found[0].inputs)
      if (['go', 'hit', 'zap', 'look'].indexOf(n.callee?.name) !== -1) {
        // Remove first argument; convert to field
        // TODO: make general, not just based on callee.name being one of the methods where we do this
        const toArg = args.splice(0, 1)
        out.fields = { to: toArg[0].fields.TEXT }
        if (args.length) {
          // Remove second argument; convert to field
          const squaresArg = args.splice(0, 1)
          out.fields.steps = '' + squaresArg[0].fields.NUM // Convert to string, dropdowns expect that
        }
      }
      for (let i = 0; i < args.length; ++i) {
        out.inputs[inputs[i]] = { block: args[i] }
      }
    } else {
      // console.log('NO INPUT', found[0])
    }

    if (ctx.context !== 'value' && found[0].output) {
      return {
        type: 'expression_statement',
        inputs: {
          EXPRESSION: { block: out }
        }
      }
    }

    return out
  }

  static ConvertFunctionDeclaration (n, ctx) {
    ctx.scope[n.id.name] = { type: 'fx', n }
    // console.log('FX', n)
    const o = {
      type: 'procedures_defnoreturn',
      extraState: { params: [] },
      fields: {
        NAME: n.id.name
      },
      inputs: {}
    }

    for (const p of n.params) {
      ctx.scope[p.name] = { type: 'var' }
      o.extraState.params.push({ name: p.name, id: p.name })
    }

    if (n.body && n.body.body.length > 0) { o.inputs.STACK = { block: convert(n.body, { ...ctx, nospace: true })[0] } }

    return o
  }

  static ConvertIdentifier (n, ctx) {
    if (n.name in ctx.scope && ctx.scope[n.name].type === 'var') {
      return {
        type: 'variables_get',
        fields: { VAR: { id: n.name } }
      }
    }
    const found = findOne(ctx.plan, x => fuzzyMatch(n, x[1]), `Unknown variable ${n.name}`)
    return {
      type: found[0].type
    }
  }

  static ConvertUnaryExpression (n, ctx) {
    return null
  }

  static ConvertMemberExpression (n, ctx) {
    if (n.computed === true) {
      return {
        type: 'lists_getIndex',
        fields: {
          MODE: 'GET',
          WHERE: 'FROM_START'
        },
        inputs: {
          AT: { block: convert(n.property, ctx) },
          VALUE: { block: convert(n.object, ctx) }
        }
      }
    }

    if (n.property.type === 'Identifier' && n.property.name === 'length') {
      return {
        type: 'lists_length',
        input: {
          VALUE: { block: convert(n.object, ctx) }
        }
      }
    }

    const found = findOne(ctx.plan, x => fuzzyMatch(n, x[1]), `Couldn't find match for ${JSON.stringify(n)}`)
    // console.log(found)
    return {
      type: found[0].type
    }
  }
}

function convert (node, ctx) {
  if (Array.isArray(node)) {
    const result = []
    for (const n of node) {
      if (n.leadingComments) {
        for (const c of n.leadingComments) {
          if (/[Δ∆]/.test(c.value)) continue
          c.handled = true
          result.push({
            type: 'comment',
            fields: {
              COMMENT: c.value.substr(1)
            },
            start: c.loc.start.line,
            end: c.loc.end.line
          })
        }
      }
      const o = convert(n, ctx)
      result.push(o)
    }
    return nextify(result, ctx)
  }
  try {
    if (!Converters[`Convert${node.type}`]) {
      console.log(node)
      throw new Error(`No converter for ${node.type}`)
    }
    const b = Converters[`Convert${node.type}`](node, ctx)
    if (b && node.loc) {
      b.start = node.loc.start.line
      b.end = node.loc.end.line
    }
    return b
  } catch (e) {
    console.error('EN', ctx.context, node, e)
    let code

    if (node && node.range) code = ctx.code.substr(node.range[0], node.range[1] - node.range[0])
    else if (node) code = ctx.code.substr(node.start, node.end - node.start)

    return {
      type: ctx.context === 'value' ? 'raw_code_value' : 'raw_code',
      fields: {
        CODE: code || '<CoDe>'
      }
    }
  }
}

function findAllBlocks (thing) {
  const result = []
  for (const o of thing) {
    if (o.contents) result.push(...findAllBlocks(o.contents))
    else if (o.kind === 'block') result.push(o)
  }
  return result
}

function doParse (blocklySource) {
  const { parse } = window.esper.plugins.babylon.babylon
  if (/^continue;\s*/.test(blocklySource)) return { type: 'ContinueStatement' }
  if (/^break;\s*/.test(blocklySource)) return { type: 'BreakStatement' }
  if (/^return;\s*/.test(blocklySource)) return { type: 'ReturnStatement' }
  if (/^'';\s*/.test(blocklySource)) return { type: 'StringLiteral' }

  const ast = parse(blocklySource, { errorRecovery: true })
  if (ast.program.body.length !== 1) return null
  let node = ast.program.body[0]
  if (!node) return ast
  let expression = false
  if (node.type === 'ExpressionStatement') {
    expression = true
    node = node.expression
  }
  return { ...node, expression }
}

function nextify (arr, ctx) {
  let result
  let target

  for (const e of arr) {
    if (e === null) continue
    if (!result) {
      result = [e]
      target = e
    } else if (target.type === 'procedures_defnoreturn' || e.type === 'procedures_defnoreturn') {
      result.push(e)
      target = e
    } else if (target.end === e.start - 1) {
      target.next = { block: e }
      target = e
    } else {
      if (ctx.nospace) {
        target.next = { block: { type: 'newline', next: { block: e } } }
        target = e
      } else {
        // console.log('BREAK', e.loc, target.loc)
        result.push(e)
        target = e
      }
    }
  }
  return result
}

function prepareBlockIntelligence ({ toolbox, blocklyState, workspace }) {
  const plan = []

  // console.log('prepareBlockIntelligence', arguments[0])
  // window.ws = workspace
  const blocks = findAllBlocks(toolbox.fullContents)

  for (const block of blocks) {
    const zeblock = Blockly.Blocks[block.type]
    // console.log('Consider', block, 'z', zeblock)
    workspace.clear()
    const defn = {
      type: block.type
    }
    defn.setupInfo = zeblock.setupInfo || 'NO SETUP INFO'
    if (zeblock.setupInfo) {
      if (zeblock.setupInfo.args0) {
        defn.inputs = {}
        defn.output = zeblock.setupInfo.output === null

        for (const entry of zeblock.setupInfo.args0) {
          // console.log(entry)
          if (entry.type === 'field_image') {
            // Don't add an input; it's just decoration
          } else if (['to', 'steps', 'squares'].includes(entry.name) && entry.type === 'field_dropdown') {
            // Don't add an input.
          } else if (entry.check === 'Number') {
            defn.inputs[entry.name] = {
              block: {
                type: 'math_number',
                fields: {
                  NUM: 0
                }
              }
            }
          } else {
            defn.inputs[entry.name] = {
              block: {
                type: 'text',
                fields: {
                  TEXT: '$ARGUMENT$' + entry.name
                }
              }
            }
          }
        }
      }
    }

    try {
      Blockly.serialization.blocks.append(defn, workspace)
      // const state = Blockly.serialization.workspaces.save(workspace) // I don't think we need this
      let blocklySource = javascriptGenerator.workspaceToCode(workspace)
      if (['☃\n', "Couldn't read code.\n"].includes(blocklySource)) {
        // Parser chokes on this whitespace trimming avoidance hack; ignore it here.
        blocklySource = ''
      }
      const blx = doParse(blocklySource)
      // console.log('BS[' + blocklySource + ']', blx)
      if (blx !== null) plan.push([defn, blx, blocklySource])
    } catch (e) {
      console.error('Could not prepare block definition:', defn)
      console.error(e)
    }
  }

  return { RobIsAwesome: true, plan }
}

function addInsertionPoints ({ code, originalCode, codeLanguage }) {
  if (codeLanguage === 'javascript') {
    // Add special arrow block to point out blocks ending with empty lines, indicating code should go there
    code = code.replace(/\n( {4,})\n([ ]*\})/gm, (_, s, s2) => `${s}\n__arrow__()${s2}`)
  }

  // Add special arrow block to point out code insertion points after comments (only after intro comment section end)
  const codeLines = code.split('\n')
  const originalLines = originalCode.split('\n')
  let newCode = ''
  let previousLine = null
  let previousLineHadComment = false
  let previousLineHadCode = false
  let previousLineWasBlank = false
  let pastIntroComments = false
  const commentStart = { javascript: '//', python: '#', lua: '--' }[codeLanguage] || '//'
  const singleLineCommentRegex = new RegExp(`[ \t]*(${commentStart})[^"'\n]*`)

  for (let i = 0; i < codeLines.length; ++i) {
    const line = codeLines[i]
    const originalLine = originalLines[i]
    // Find whether the line has changed. It might just be that the line was shifted around by the player inserting more code.
    // We also look for the unchanged comment line in a new position to find what line we're really on.
    const originalLineMovedIndex = originalLines.indexOf(previousLine)
    const lineHasComment = singleLineCommentRegex.test(line)
    const lineHasChanged = line !== originalLine && (originalLineMovedIndex === -1 || line !== originalLines[originalLineMovedIndex])
    const lineIsBlank = !line.trim()[0]
    const lineHasCode = !lineIsBlank && !lineHasComment
    if (lineHasCode || previousLineWasBlank) {
      pastIntroComments = true
    }
    const isEntryPoint = lineIsBlank && previousLineHadComment && !previousLineHadCode && pastIntroComments && !lineHasChanged
    if (isEntryPoint) {
      newCode += line + '__arrow__()\n'
    } else {
      newCode += line + '\n'
    }
    previousLine = line
    previousLineHadComment = lineHasComment
    previousLineHadCode = lineHasCode
    previousLineWasBlank = lineIsBlank
    pastIntroComments = pastIntroComments || lineHasCode || previousLineWasBlank
  }
  return newCode
}

function codeToBlocks ({ code, originalCode, codeLanguage, prepData }) {
  let ast
  try {
    code = addInsertionPoints({ code, originalCode, codeLanguage })
    switch (codeLanguage) {
      case 'javascript':
      {
        const { parse } = window.esper.plugins.babylon.babylon
        ast = parse(code + '\n__donothing__()', { errorRecovery: true })
        break
      }
      case 'python':
      {
        const { parse } = window.esper.plugins['lang-python'].skulpty
        code = code.replace(/^(\s*)#(.*)$/gm, (_, s, c) => `${s}__comment__(${JSON.stringify(c)})`)
        ast = parse(code, { errorRecovery: true, naive: true, locations: true, startend: true })
        // console.log("PGC", ast, require("@babel/generator").default(ast).code)
        ast = { type: 'File', program: ast }
        // console.log('OYY', ast)
        break
      }
    }
  } catch (e) {
    console.error("Oh no, couldn't parse", code, e)
  }
  const ctx = {
    plan: prepData.plan,
    scope: {},
    context: 'statement',
    code
  }
  const out = {
    blocks: convert(ast.program, ctx),
    variables: []
  }
  for (const v in ctx.scope) {
    if (ctx.scope[v].type === 'var') out.variables.push({ name: v, id: v })
  }
  // console.log('OUT', out)
  return out
}

module.exports = {
  prepareBlockIntelligence,
  codeToBlocks
}
