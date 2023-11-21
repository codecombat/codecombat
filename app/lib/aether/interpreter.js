// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS104: Avoid inline assignments
 * DS202: Simplify dynamic range loops
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let upgradeEvaluator;
const {
  addedGlobals
} = require('./protectBuiltins');

const isStatement = name => ![
  'Literal', 'Identifier', 'ThisExpression', 'BlockStatement', 'MemberExpression',
  'FunctionExpression', 'LogicalExpression', 'BinaryExpression', 'UnaryExpression',
  'Program'
].includes(name);

const shouldFlow = name => ![
  'IfStatement', 'WhileStatement', 'DoWhileStatement', 'ForStatement', 'ForInStatement', 'ForOfStatement'
].includes(name);

const updateState = function(aether, evaluator) {
  let x;
  const frame_stack = evaluator.frames;
  const top = frame_stack[0];
  const bottom = frame_stack[frame_stack.length - 1];

  if (aether.options.includeFlow) {
    if (bottom.flow == null) {
      bottom.flow = {statementsExecuted: 0, statements: []};
      if (aether.flow.states == null) { aether.flow.states = []; }
      aether.flow.states.push(bottom.flow);
    }
  }

  if (aether.options.includeMetrics) {
    if (aether.metrics.statementsExecuted == null) { aether.metrics.statementsExecuted = 0; }
    if (aether.metrics.callsExecuted == null) { aether.metrics.callsExecuted = 0; }
  }

  const astStack = ((() => {
    const result = [];
    for (x of Array.from(frame_stack)) {       if (x.ast != null) {
        result.push(x.ast);
      }
    }
    return result;
  })());
  const statementStack = ((() => {
    const result1 = [];
     for (x of Array.from(astStack)) {       if (isStatement(x.type)) {
        result1.push(x);
      }
    } 
    return result1;
  })());

  if (top.ast != null) {
    if (aether.options.includeMetrics && (top.ast.type === 'CallExpression')) { ++aether.metrics.callsExecuted; }

    if (isStatement(top.ast.type)) {
      if (aether.options.includeMetrics) { ++aether.metrics.statementsExecuted; }
      if (bottom.flow != null) { ++bottom.flow.statementsExecuted; }

      if ((bottom.flow != null) && shouldFlow(top.ast.type)) {
        let start;
        const f = {};
        if (aether._userInfo != null) { f.userInfo = _.cloneDeep(aether._userInfo); }
        if (!aether.options.noVariablesInFlow) {
          let asc, s;
          const variables = {};
          for (start = frame_stack.length - 2, s = start, asc = start <= 0; asc ? s <= 0 : s >= 0; asc ? s++ : s--) {
            var p = frame_stack[s];
            if (!p || !p.scope) { continue; }
            for (var n of Array.from(Object.keys(p.scope.object.properties))) {
              if (n[0] === '_') { continue; }
              if (p.value) { variables[n] = p.value.debugString; }
            }
          }
          f.variables = variables;
        }

        let rng = top.ast.originalRange;

        if (!rng && (top.ast.loc != null)) {
          if (top.ast.loc.start && !top.ast.loc.end) {
            top.ast.loc.end = top.ast.loc.start;
          }
          rng = {
            start: {row:top.ast.loc.start.line - 1, col:top.ast.loc.start.column},
            end: {row:top.ast.loc.end.line - 1, col:top.ast.loc.end.column}
          };
        }

        if (rng) { f.range = [rng.start, rng.end]; }
        f.type = top.ast.type;

        if (!!f.range) { return bottom.flow.statements.push(f); } // Dont push statements without ranges
      }
    }
  }
};

/*
  This is the primary method that is called to generate an AST.

  Coffeescript is handled as an edge case as the option inFunctionBody breaks all our
  coffeescript examples.
  For example, this breaks with a syntax error:
  ```
  esper.languages.coffeescript.parser("# Rawr", {inFunctionBody: true})
  ```
*/
module.exports.parse = function(aether, code) {
  let left, left1;
  const esper = (left = (left1 = (typeof window !== 'undefined' && window !== null ? window.esper : undefined) != null ? (typeof window !== 'undefined' && window !== null ? window.esper : undefined) : (typeof self !== 'undefined' && self !== null ? self.esper : undefined)) != null ? left1 : (typeof global !== 'undefined' && global !== null ? global.esper : undefined)) != null ? left : require('esper.js');
  esper.plugin('lang-' + aether.language.id);
  const {
    realm
  } = new esper.Engine({language: aether.language.id});
  if (['coffeescript'].includes(aether.language.id)) { return realm.parser(code); }
  return realm.parser(code, {inFunctionBody: true});
};
  // return esper.languages[aether.language.id].parser(code) if aether.language.id in ["coffeescript"]
  // return esper.languages[aether.language.id].parser(code, inFunctionBody: true)

/*
  Creates an instrumented function that we can execute.
*/
module.exports.createFunction = function(aether) {
  let fx, left, left1;
  const esper = (left = (left1 = (typeof window !== 'undefined' && window !== null ? window.esper : undefined) != null ? (typeof window !== 'undefined' && window !== null ? window.esper : undefined) : (typeof self !== 'undefined' && self !== null ? self.esper : undefined)) != null ? left1 : (typeof global !== 'undefined' && global !== null ? global.esper : undefined)) != null ? left : require('esper.js');
  esper.plugin('lang-' + aether.language.id);
  const state = {};
  let messWithLoops = false;
  if (aether.options.whileTrueAutoYield || aether.options.simpleLoops) {
    messWithLoops = true;
  }

  if (!aether.esperEngine) {
    aether.esperEngine = new esper.Engine({
      strict: !['python', 'lua'].includes(aether.language.id),
      foreignObjectMode: aether.options.protectAPI ? 'smart' : 'link',
      extraErrorInfo: true,
      yieldPower: 2,
      debug: aether.options.debug,
      language: aether.language.id
    });
  }

  const engine = aether.esperEngine;

  const fxName = aether.options.functionName || 'foo';

  aether.language.setupInterpreter(engine);

  for (var name of Array.from(Object.keys(addedGlobals))) {
    engine.addGlobal(name, addedGlobals[name]);
  }

  upgradeEvaluator(aether, engine.evaluator);
  try {
    // Hopefully no language uses FunctionWrapping.
    if (aether.language.usesFunctionWrapping()) {
      engine.evalASTSync(aether.ast);
      if (aether.options.yieldConditionally) {
        fx = engine.fetchFunction(fxName, makeYieldFilter(aether));
      } else if (aether.options.yieldAutomatically) {
        fx = engine.fetchFunction(fxName, engine => true);
      } else {
        fx = engine.fetchFunctionSync(fxName);
      }
    } else {
      if (aether.options.yieldConditionally) {
        fx = engine.functionFromAST(aether.ast, makeYieldFilter(aether));
      } else if (aether.options.yieldAutomatically) {
        fx = engine.functionFromAST(aether.ast, engine => true);
      } else {
        fx = engine.functionFromASTSync(aether.ast);
      }
    }
  } catch (error) {
    console.error('Esper: error parsing AST. Returning empty function.', error.message, error);
    if (aether.language.id === 'javascript') {
      error.message = "Couldn't understand your code. Are your { and } braces matched?";
    } else {
      error.message = "Couldn't understand your code. Do you have extra spaces at the beginning, or unmatched ( and ) parentheses?";
    }
    aether.addProblem(aether.createUserCodeProblem({error, code: aether.raw, type: 'transpile', reporter: 'aether'}));
    engine.evalASTSync(emptyAST);
  }

  return fx;
};



const debugDumper = _.debounce(evaluator => evaluator.dumpProfilingInformation()
,5000);

var makeYieldFilter = aether => (function(engine, evaluator, e) {

  const frame_stack = evaluator.frames;
  //console.log x.type + " " + x.ast?.type for x in frame_stack
  //console.log "----"

  const top = frame_stack[0];


  if ((e != null) && (e.type === 'event') && (e.event === 'loopBodyStart')) {

    // Legacy programming languages use 'Literal' whilst C++ and Java use 'BooleanLiteral'.
    // Lua generates `while true` loops from code like `for i, soldier in pairs(soldiers do)`, so for Lua, we ignore `true` test literals that don't have `loc` (because they are generated code)
    if ((top.srcAst.type === 'WhileStatement') && ((top.srcAst.test.type === 'Literal') || (top.srcAst.test.type === 'BooleanLiteral')) && !((aether.language.id === 'lua') && !top.srcAst.test.loc)) {
      if (aether.whileLoopMarker != null) {
        const currentMark = aether.whileLoopMarker(top);
        if (currentMark === top.mark) {
          // console.log "[Aether] Frame #{this.world.age}: Forcing while-true loop to yield, repeat #{currentMark}"
          top.mark = currentMark + 1;
          return true;
        } else {
          // console.log "[Aether] Frame #{this.world.age}: Loop Avoided, mark #{top.mark} isnt #{currentMark}"
          top.mark = currentMark;
        }
      }
    }
  }

  if (aether._shouldYield) {
    const yieldValue = aether._shouldYield;
    aether._shouldYield = false;
    if (frame_stack[1].type === 'loop') { frame_stack[1].didYield = true; }
    return true;
  }

  return false;
});

module.exports.createThread = function(aether, fx) {
  const internalFx = esper.Value.getBookmark(fx);
  const engine = aether.esperEngine.fork();
  upgradeEvaluator(aether, engine.evaluator);
  return engine.makeFunctionFromClosure(internalFx, makeYieldFilter(aether));
};

module.exports.upgradeEvaluator = (upgradeEvaluator = function(aether, evaluator) {
  let executionCount = 0;
  return evaluator.instrument = function(evalu, evt) {
    debugDumper(evaluator);
    if (++executionCount > aether.options.executionLimit) {
      throw new TypeError('Statement execution limit reached');
    }
    return updateState(aether, evalu, evt);
  };
});


var emptyAST = {"type":"Program","body":[{"type":"FunctionDeclaration","id":{"type":"Identifier","name":"plan","range":[9,13],"loc":{"start":{"line":1,"column":9},"end":{"line":1,"column":13}},"originalRange":{"start":{"ofs":-8,"row":0,"col":-8},"end":{"ofs":-4,"row":0,"col":-4}}},"params":[],"defaults":[],"body":{"type":"BlockStatement","body":[{"type":"VariableDeclaration","declarations":[{"type":"VariableDeclarator","id":{"type":"Identifier","name":"hero"},"init":{"type":"ThisExpression"}}],"kind":"var","userCode":false}],"range":[16,19],"loc":{"start":{"line":1,"column":16},"end":{"line":2,"column":1}},"originalRange":{"start":{"ofs":-1,"row":0,"col":-1},"end":{"ofs":2,"row":1,"col":1}}},"rest":null,"generator":false,"expression":false,"range":[0,19],"loc":{"start":{"line":1,"column":0},"end":{"line":2,"column":1}},"originalRange":{"start":{"ofs":-17,"row":0,"col":-17},"end":{"ofs":2,"row":1,"col":1}}}],"range":[0,19],"loc":{"start":{"line":1,"column":0},"end":{"line":2,"column":1}},"originalRange":{"start":{"ofs":-17,"row":0,"col":-17},"end":{"ofs":2,"row":1,"col":1}}};
