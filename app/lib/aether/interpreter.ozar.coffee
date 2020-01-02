addedGlobals = require('./protectBuiltins').addedGlobals

isStatement = (name) ->
  name not in [
    'Literal', 'Identifier', 'ThisExpression', 'BlockStatement', 'MemberExpression',
    'FunctionExpression', 'LogicalExpression', 'BinaryExpression', 'UnaryExpression',
    'Program'
  ]

shouldFlow = (name) ->
  name not in [
    'IfStatement', 'WhileStatement', 'DoWhileStatement', 'ForStatement', 'ForInStatement', 'ForOfStatement'
  ]

updateState = (aether, evaluator) ->
  frame_stack = evaluator.frames
  top = frame_stack[0]
  bottom = frame_stack[frame_stack.length - 1]

  if aether.options.includeFlow
    unless bottom.flow?
      bottom.flow = {statementsExecuted: 0, statements: []}
      aether.flow.states ?= []
      aether.flow.states.push bottom.flow

  if aether.options.includeMetrics
    aether.metrics.statementsExecuted ?= 0
    aether.metrics.callsExecuted ?= 0

  astStack = (x.ast for x in frame_stack when x.ast?)
  statementStack = ( x for x in astStack when isStatement x.type )

  if top.ast?
    ++aether.metrics.callsExecuted if aether.options.includeMetrics and top.ast.type == 'CallExpression'

    if isStatement top.ast.type
      ++aether.metrics.statementsExecuted if aether.options.includeMetrics
      ++bottom.flow.statementsExecuted if bottom.flow?

      if bottom.flow? and shouldFlow(top.ast.type)
        f = {}
        f.userInfo = _.cloneDeep aether._userInfo if aether._userInfo?
        unless aether.options.noVariablesInFlow
          variables = {}
          for s in [(frame_stack.length - 2) .. 0]
            p = frame_stack[s]
            continue unless p and p.scope
            for n in Object.keys(p.scope.object.properties)
              continue if n[0] is '_'
              variables[n] = p.value.debugString if p.value
          f.variables = variables

        rng = top.ast.originalRange

        if not rng and top.ast.loc?
          rng =
            start: {row:top.ast.loc.start.line - 1, col:top.ast.loc.start.column}
            end: {row:top.ast.loc.end.line - 1, col:top.ast.loc.end.column}

        f.range = [rng.start, rng.end] if rng
        f.type = top.ast.type

        bottom.flow.statements.push f unless not f.range # Dont push statements without ranges

###
  This is the primary method that is called to generate an AST.

  Coffeescript is handled as an edge case as the option inFunctionBody breaks all our
  coffeescript examples.
  For example, this breaks with a syntax error:
  ```
  esper.languages.coffeescript.parser("# Rawr", {inFunctionBody: true})
  ```
###
module.exports.parse = (aether, code) ->
  esper = window?.esper ? self?.esper ? global?.esper ? require 'esper.js'
  esper.plugin 'lang-' + aether.language.id
  return esper.languages[aether.language.id].parser(code) if aether.language.id in ["coffeescript"]
  return esper.languages[aether.language.id].parser(code, inFunctionBody: true)

###
  Creates an instrumented function that we can execute.
###
module.exports.createFunction = (aether) ->
  esper = window?.esper ? self?.esper ? global?.esper ? require 'esper.js'
  esper.plugin 'lang-' + aether.language.id
  state = {}
  messWithLoops = false
  if aether.options.whileTrueAutoYield or aether.options.simpleLoops
    messWithLoops = true

  unless aether.esperEngine
    aether.esperEngine = new esper.Engine
      strict: aether.language.id not in ['python', 'lua']
      foreignObjectMode: if aether.options.protectAPI then 'smart' else 'link'
      extraErrorInfo: true
      yieldPower: 2
      debug: aether.options.debug
      language: aether.language.id

  engine = aether.esperEngine

  fxName = aether.options.functionName or 'foo'

  aether.language.setupInterpreter engine

  for name in Object.keys addedGlobals
    engine.addGlobal(name, addedGlobals[name])

  upgradeEvaluator aether, engine.evaluator
  try
    # Hopefully no language uses FunctionWrapping.
    if aether.language.usesFunctionWrapping()
      engine.evalASTSync aether.ast
      if aether.options.yieldConditionally
        fx = engine.fetchFunction fxName, makeYieldFilter(aether)
      else if aether.options.yieldAutomatically
        fx = engine.fetchFunction fxName, (engine) -> true
      else
        fx = engine.fetchFunctionSync fxName
    else
      if aether.options.yieldConditionally
        fx = engine.functionFromAST aether.ast, makeYieldFilter(aether)
      else if aether.options.yieldAutomatically
        fx = engine.functionFromAST aether.ast, (engine) -> true
      else
        fx = engine.functionFromASTSync aether.ast
  catch error
    console.log 'Esper: error parsing AST. Returning empty function.', error.message
    if aether.language.id is 'javascript'
      error.message = "Couldn't understand your code. Are your { and } braces matched?"
    else
      error.message = "Couldn't understand your code. Do you have extra spaces at the beginning, or unmatched ( and ) parentheses?"
    aether.addProblem aether.createUserCodeProblem error: error, code: aether.raw, type: 'transpile', reporter: 'aether'
    engine.evalASTSync emptyAST

  return fx



debugDumper = _.debounce (evaluator) ->
  evaluator.dumpProfilingInformation()
,5000

makeYieldFilter = (aether) -> (engine, evaluator, e) ->

  frame_stack = evaluator.frames
  #console.log x.type + " " + x.ast?.type for x in frame_stack
  #console.log "----"

  top = frame_stack[0]


  if e? and e.type is 'event' and e.event is 'loopBodyStart'
    
    if top.srcAst.type is 'WhileStatement' and top.srcAst.test.type is 'Literal'
      if aether.whileLoopMarker?
        currentMark = aether.whileLoopMarker(top)
        if currentMark is top.mark
          # console.log "[Aether] Frame #{this.world.age}: Forcing while-true loop to yield, repeat #{currentMark}"
          top.mark = currentMark + 1
          return true
        else
          # console.log "[Aether] Frame #{this.world.age}: Loop Avoided, mark #{top.mark} isnt #{currentMark}"
          top.mark = currentMark

  if aether._shouldYield
    yieldValue = aether._shouldYield
    aether._shouldYield = false
    frame_stack[1].didYield = true if frame_stack[1].type is 'loop'
    return true

  return false

module.exports.createThread = (aether, fx) ->
  internalFx = esper.Value.getBookmark fx
  engine = aether.esperEngine.fork()
  upgradeEvaluator aether, engine.evaluator
  return engine.makeFunctionFromClosure internalFx, makeYieldFilter(aether)

module.exports.upgradeEvaluator = upgradeEvaluator = (aether, evaluator) ->
  executionCount = 0
  evaluator.instrument = (evalu, evt) ->
    debugDumper evaluator
    if ++executionCount > aether.options.executionLimit
      throw new TypeError 'Statement execution limit reached'
    updateState aether, evalu, evt


emptyAST = {"type":"Program","body":[{"type":"FunctionDeclaration","id":{"type":"Identifier","name":"plan","range":[9,13],"loc":{"start":{"line":1,"column":9},"end":{"line":1,"column":13}},"originalRange":{"start":{"ofs":-8,"row":0,"col":-8},"end":{"ofs":-4,"row":0,"col":-4}}},"params":[],"defaults":[],"body":{"type":"BlockStatement","body":[{"type":"VariableDeclaration","declarations":[{"type":"VariableDeclarator","id":{"type":"Identifier","name":"hero"},"init":{"type":"ThisExpression"}}],"kind":"var","userCode":false}],"range":[16,19],"loc":{"start":{"line":1,"column":16},"end":{"line":2,"column":1}},"originalRange":{"start":{"ofs":-1,"row":0,"col":-1},"end":{"ofs":2,"row":1,"col":1}}},"rest":null,"generator":false,"expression":false,"range":[0,19],"loc":{"start":{"line":1,"column":0},"end":{"line":2,"column":1}},"originalRange":{"start":{"ofs":-17,"row":0,"col":-17},"end":{"ofs":2,"row":1,"col":1}}}],"range":[0,19],"loc":{"start":{"line":1,"column":0},"end":{"line":2,"column":1}},"originalRange":{"start":{"ofs":-17,"row":0,"col":-17},"end":{"ofs":2,"row":1,"col":1}}}
