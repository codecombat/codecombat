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
    case 'BreakStatement':
    case 'ContinueStatement':
      return true
    case 'WhileStatement':
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
    console.log('Decl', n)
    if (n.declarations.length !== 1) throw new Error('No multi decls pls')
    const [d] = n.declarations

    ctx.scope[d.id.name] = d

    if (!d.init) return null
    return {
      type: 'variables_set',
      fields: { VAR: { id: d.id.name } },
      inputs: {
        VALUE: { block: convert(d.init, ctx) }
      }
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
      fields: { BOOL: n.value }
    }
  }

  static ConvertBlockStatement (n, ctx) {
    return convert(n.body, ctx)
  }

  static ConvertExpressionStatement (n, ctx) {
    return convert(n.expression, ctx)
  }

  static ConvertBreakStatement (n, ctx) {
    return findOne(ctx.plan, x => fuzzyMatch(n, x[1]), 'Can\'t find the break statement')[0]
  }

  static ConvertContinueStatement (n, ctx) {
    console.log(n)
    return findOne(ctx.plan, x => fuzzyMatch(n, x[1]), 'Can\'t find the continue statement')[0]
  }

  static ConvertWhileStatement (n, ctx) {
    const found = findOne(ctx.plan, x => fuzzyMatch(n, x[1]), 'Can\'t find the while statement')
    const body = convert(n.body, { ...ctx, nospace: true })
    return {
      type: found[0].type,
      inputs: {
        BOOL: { block: convert(n.test, ctx) },
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
        IF0: { block: convert(n.test, ctx) },
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
        VALUE: { block: convert(n.right, ctx) }
      }
    }
  }

  static ConvertBinaryExpression (n, ctx) {
    const [type, op] = ({
      '+': ['math_arithmetic', 'ADD'],
      '-': ['math_arithmetic', 'MINUS'],
      '*': ['math_arithmetic', 'MULTIPLY'],
      '/': ['math_arithmetic', 'DIVIDE'],

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

  static ConvertCallExpression (n, ctx) {
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

  static ConvertMemberExpression (n, ctx) {
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
              Comment: c.value.substr(1)
            },
            loc: c.loc.start.line
          })
        }
      }
      const o = convert(n, ctx)
      result.push(o)
    }
    return nextify(result, ctx)
  }
  if (!Converters[`Convert${node.type}`]) {
    console.log(node)
    throw new Error(`No converter for ${node.type}`)
  }
  const b = Converters[`Convert${node.type}`](node, ctx)
  if (b) b.loc = node.loc.start.line

  return b
}

function findAllBlocks (thing) {
  const result = []
  for (const o of thing.contents) {
    if (o.contents) result.push(...findAllBlocks(o))
    else if (o.kind === 'block') result.push(o)
  }
  return result
}

function doParse (blocklySource) {
  const { parse } = esper.plugins.babylon.babylon
  if (/^continue;\s*/.test(blocklySource)) return { type: 'ContinueStatement' }
  if (/^break;\s*/.test(blocklySource)) return { type: 'BreakStatement' }
  if (/^'';\s*/.test(blocklySource)) return { type: 'StringLiteral' }

  const ast = parse(blocklySource, { errorRecovery: true })
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
    } else if (target.loc === e.loc - 1 || ctx.nospace) {
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

function prepare ({ toolbox, blocklyState, workspace, codeLanguage }) {
  const plan = []

  console.log('prepare', arguments[0])
  window.ws = workspace
  const blocks = findAllBlocks(toolbox)

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

    Blockly.serialization.blocks.append(defn, workspace)
    const state = Blockly.serialization.workspaces.save(workspace)
    const blocklySource = javascriptGenerator.workspaceToCode(workspace)
    console.log('BS[' + blocklySource + ']')
    plan.push([defn, doParse(blocklySource), blocklySource])
  }

  return { RobIsAwesome: true, plan }
}

function codeToBlocks ({ code, codeLanguage, toolbox, blocklyState, debugDiv, debugBlocklyWorkspace, prepData }) {
  console.log('codeToBlocks', arguments[0])

  const { parse } = esper.plugins.babylon.babylon
  console.log('PLAN', prepData)
  let ast
  try {
    ast = parse(code, { errorRecovery: true })
  } catch (e) {
    console.error("Oh no, couldn't parse", code, e)
  }
  const ctx = {
    plan: prepData.plan,
    scope: {}
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
  prepare,
  codeToBlocks
}
