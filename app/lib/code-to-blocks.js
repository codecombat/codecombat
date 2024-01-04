const Blockly = require('blockly')
const { javascriptGenerator } = require('blockly/javascript')

/*
- [ ] Handle error case: if code to blocks didn't give a valid Blockly AST, don't try to update it
- [ ] Fake do while false block to imitate empty comment pointing to do some code
- [ ] Bring back tabbed flyout when there are many categories
- [ ] Replace text, text_multiline blocks to not use same quote_ implementation, so we can use double-quoted strings and not escape apostrophes
- [ ] List or text length block
- [ ] Fix performance issues
- [ ] Get Skulpty rewrite included the right way
- [ ] Clear out code generation warnings by moving to forBlock[blockType] dictionary
- [ ] Getting rid of all code should get rid of all blocks
- [ ] Make it so that blocks don't move as soon as you update them on Blockly side
- [ ] Highlight actively running blocks
- [ ] Implement block limits
- [ ] Implement more verifier-like testing harness, display problems in full but passed tests are collapsed
- [ ] Load real CoCo levels' code
*/

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
  if (matches.length !== 1) {
    console.log(matches)
    console.log(array)
    throw new Error(why + ', found ' + matches.length)
  }
  return matches[0]
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
      ctx.scope[d.id.name] = 'var'

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
    return convert(n.expression, ctx, { ...ctx, context: 'value' })
  }

  static ConvertBreakStatement (n, ctx) {
    return findOne(ctx.plan, x => fuzzyMatch(n, x[1]), 'Can\'t find the break statement')[0]
  }

  static ConvertContinueStatement (n, ctx) {
    console.log(n)
    return findOne(ctx.plan, x => fuzzyMatch(n, x[1]), 'Can\'t find the continue statement')[0]
  }

  static ConvertArrayExpression (n, ctx) {
    console.log(n)
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
    return {
      type: found[0].type,
      inputs: {
        BOOL: { block: convert(n.test, ctx) },
        DO: body ? { block: body[0] } : undefined
      }
    }
  }

  static ConvertConditionalExpression (n,ctx) {
    const found = findOne(ctx.plan, x => fuzzyMatch(n, x[1]), 'Can\'t find the ternary expression')
    const yes = convert(n.consequent, { ...ctx, nospace: true, context: 'value' })
    const no = convert(n.alternate, { ...ctx, nospace: true, context: 'value' })

    return {
      type: found[0].type,
      inputs: {
        IF: { block: convert(n.test, ctx) },
        THEN: yes ? { block: yes } : undefined,
        ELSE: no ? { block: no } : undefined
      }
    }
  }

  static ConvertForStatement (n, ctx) {
    const found = findOne(ctx.plan, x => fuzzyMatch(n, x[1]), 'Can\'t find the for statement')
    console.log("FORL", n)
    const init = convert(n.init, { ...ctx, nospace: true })
    const body = convert(n.body, { ...ctx, nospace: true, context: "statement" })

    return {
      type: found[0].type,
      inputs: {
        TIMES: { block: convert(n.test.right, ctx) },
        DO: body ? { block: body[0] } : undefined
      }
    }
  }

  static ConvertIfStatement (n, ctx) {
    console.log('IF', n)
    const conq = convert(n.consequent, { ...ctx, nospace: true })
    return {
      type: 'controls_if',
      inputs: {
        IF0: { block: convert(n.test, ctx, { ...ctx, context: 'value' }) },
        DO0: conq ? { block: conq[0] } : undefined
      }
    }
  }

  static ConvertAssignmentExpression (n, ctx) {
    if (n.operator !== '=') throw new Error(`Weird assigment operator ${n.operator}`)
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
    console.log('LE', n)
    return null
  }

  static ConvertReturnStatement (n, ctx) {
    return {
      type: 'procedures_ifreturn'
    }
  }

  static ConvertCallExpression (n, ctx) {
    if (n.callee.type === 'Identifier') {
      console.log('CALL', n, ctx.scope)

      if (ctx.scope[n.callee.name] === 'fx') {
        if (ctx.context === 'value') {
          return {
            type: 'procedures_callreturn',
            fields: {
              NAME: n.callee.name
            }
          }
        } else {
          return {
            type: 'procedures_callnoreturn',
            fields: {
              NAME: n.callee.name
            }
          }
        }
      }
    }

    const found = findOne(ctx.plan, x => fuzzyMatch(n, x[1]), `Couldn't find match for ${JSON.stringify(n)}`)
    console.log('CALL', ctx, found[0])

    const out = {
      type: found[0].type,
      inputs: {}
    }

    const args = n.arguments.map(x => convert(x, { ...ctx, context: 'value' }))
    if (found[0].inputs) {
      const inputs = Object.keys(found[0].inputs)
      for (let i = 0; i < args.length; ++i) {
        out.inputs[inputs[i]] = { block: args[i] }
      }
    } else {
      console.log('NO INPUT', found[0])
    }
    return out
  }

  static ConvertFunctionDeclaration (n, ctx) {
    ctx.scope[n.id.name] = 'fx'
    console.log('FX', n)
    return {
      type: 'procedures_defnoreturn',
      fields: {
        NAME: n.id.name
      },
      inputs: {
        STACK: { block: convert(n.body, { ...ctx, nospace: true })[0] }
      }
    }
  }

  static ConvertIdentifier (n, ctx) {
    if (n.name in ctx.scope) {
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
    console.log(found)
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
    if (ctx.context === 'value') throw e;
    return {
      type: 'raw_code',
      fields: {
        CODE: ctx.code.substr(node.start, node.end - node.start) || '<CoDe>'
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
  const { parse } = esper.plugins.babylon.babylon
  if (/^continue;\s*/.test(blocklySource)) return { type: 'ContinueStatement' }
  if (/^break;\s*/.test(blocklySource)) return { type: 'BreakStatement' }
  if (/^return;\s*/.test(blocklySource)) return { type: 'ReturnStatement' }
  if (/^'';\s*/.test(blocklySource)) return { type: 'StringLiteral' }

  const ast = parse(blocklySource, { errorRecovery: true })
  if (ast.program.body.length != 1) return null
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
    } else if (target.end === e.start - 1 || ctx.nospace) {
      target.next = { block: e }
      target = e
    } else {
      console.log('BREAK', e.loc, target.loc)
      result.push(e)
      target = e
    }
  }
  return result
}

function prepareBlockIntelligence ({ toolbox, blocklyState, workspace }) {
  const plan = []

  console.log('prepareBlockIntelligence', arguments[0])
  window.ws = workspace
  const blocks = findAllBlocks(toolbox.fullContents)

  for (const block of blocks) {
    const zeblock = Blockly.Blocks[block.type]
    console.log('Consiter', block, 'z', zeblock)
    workspace.clear()
    const defn = {
      type: block.type,
      fields: block.fields
    }
    defn.setupInfo = zeblock.setupInfo || 'NO SETUP INFO'
    if (zeblock.setupInfo) {
      if (zeblock.setupInfo.args0) {
        defn.inputs = {}

        for (const entry of zeblock.setupInfo.args0) {
          console.log(entry)
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

    try {
      Blockly.serialization.blocks.append(defn, workspace)
      const state = Blockly.serialization.workspaces.save(workspace)
      const blocklySource = javascriptGenerator.workspaceToCode(workspace)
      const blx = doParse(blocklySource)
      console.log('BS[' + blocklySource + ']', blx)
      if (blx !== null) plan.push([defn, blx, blocklySource])
    } catch (e) {
      console.error(e)
    }
  }

  return { RobIsAwesome: true, plan }
}

function codeToBlocks ({ code, codeLanguage, toolbox, blocklyState, debugDiv, debugBlocklyWorkspace, prepData }) {
  console.log('codeToBlocks', arguments[0])

  console.log('PLAN', prepData)
  let ast
  try {
    switch (codeLanguage) {
      case 'javascript':
      {
        const { parse } = esper.plugins.babylon.babylon
        ast = parse(code, { errorRecovery: true })
        break
      }
      case 'python':
      {
        //const { parse } = esper.plugins['lang-python'].skulpty
        const { parse } = require('skulpty')
        ast = parse(code, { errorRecovery: true, naive: true })
        ast = { type: 'File', program: ast }
        console.log('OYY', ast)
        break
      }
    }
  } catch (e) {
    console.error("Oh no, couldn't parse", code, e)
  }
  const ctx = {
    plan: prepData.plan,
    scope: {},
    code
  }
  const out = {
    blocks: convert(ast.program, ctx),
    variables: []
  }
  for (const v in ctx.scope) {
    out.variables.push({ name: v, id: v })
  }
  $(debugDiv).text('OK')
  console.log('OUT', out)
  return out
}

module.exports = {
  prepareBlockIntelligence,
  codeToBlocks
}
