const Blockly = require('blockly')
const { javascriptGenerator } = require('blockly/javascript')

class Converters {
  static ConvertProgram (n, ctx) {
    return convert(n.body, ctx)
  }

  static ConvertExpressionStatement (n, ctx) {
    return convert(n.expression, ctx)
  }

  static ConvertCallExpression (n, ctx) {
    const target = convert(n.callee, { ...ctx, context: 'call' })
    const args = convert(n.arguments, { ...ctx, context: 'value' })
    return [target, args]
  }

  static ConvertMemberExpression (n, ctx) {
    if (n.object.type === 'Identifier' && n.object.name === 'hero') {
      return 'HERO'
    }

    const o = convert(n.object)
    const p = convert(n.property)
    return [o, p]
  }
}

function convert (node, ctx) {
  if (Array.isArray(node)) return node.map(convert)
  if (!Converters[`Convert${node.type}`]) {
    console.log(node)
    throw new Error(`No converter for ${node.type}}`)
  }
  return Converters[`Convert${node.type}`](node, ctx)
}

function findAllBlocks (thing) {
  const result = []
  for (const o of thing.contents) {
    if (o.contents) result.splice(-1, 0, ...findAllBlocks(o))
    else if (o.kind === 'block') result.push(o)
  }
  return result
}

function doParse(blocklySource) {
  const { parse } = esper.plugins.babylon.babylon
  if (/^continue;\s*/.test(blocklySource)) return { type: "ContinueStatement" };
  if (/^break;\s*/.test(blocklySource)) return { type: "BreakStatement" };


  const ast = parse(blocklySource, { errorRecovery: true })
  let node = ast.program.body[0]
  if (!node) return ast
  let expression = false
  if (node.type === "ExpressionStatement") {
    expression = true
    node = node.expression
  }
  return { ...node, expression }
}

function prepare ({ toolbox, blocklyState, workspace }) {
  let plan = [];

  console.log('prepare', arguments[0])
  window.ws = workspace
  const blocks = findAllBlocks(toolbox)

  for (const block of blocks) {
    const zeblock = Blockly.Blocks[block.type]
    console.log('Consiter', block, 'z', zeblock)
    workspace.clear()
    const defn = {
      type: block.type
    }
    if (zeblock.setupInfo) {
      if (zeblock.setupInfo.args0) {
        defn.inputs = {}

        for (const entry of zeblock.setupInfo.args0) {
          console.log(entry)
          defn.inputs[entry.name] = {
            block: {
              type: 'text',
              fields: {
                TEXT: "$ARGUMENT$" + entry.name
              }
            }
          }
        }
      }
    }
    console.log(defn)
    Blockly.serialization.blocks.append(defn, workspace)
    const state = Blockly.serialization.workspaces.save(workspace)
    console.log(state)
    const blocklySource = javascriptGenerator.workspaceToCode(workspace)
    console.log("BS[" + blocklySource + "]")
    plan.push([block, doParse(blocklySource), blocklySource])
  }

  return { RobIsAwesome: true, plan }
}

function codeToBlocks ({ code, codeLanguage, toolbox, blocklyState, debugDiv, prepData }) {
  console.log('codeToBlocks', arguments[0])

  const { parse } = esper.plugins.babylon.babylon
  console.log("PLAN", prepData);
  const out = convert(parse(code).program)
  $(debugDiv).text(JSON.stringify(out))

  return {
    blocks: {
      blocks: [
        { type: 'Sword of the Temple Guard_attack', next: {block: { type: 'Sword of the Temple Guard_attack' }} }
      ]
    }
  }
}

module.exports = {
  prepare,
  codeToBlocks
}
