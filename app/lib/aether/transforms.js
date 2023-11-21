// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS104: Avoid inline assignments
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let left, left1, makeCheckIncompleteMembers, makeCheckThisKeywords, makeGatherNodeRanges;
const _ = (left = (left1 = (typeof window !== 'undefined' && window !== null ? window._ : undefined) != null ? (typeof window !== 'undefined' && window !== null ? window._ : undefined) : (typeof self !== 'undefined' && self !== null ? self._ : undefined)) != null ? left1 : (typeof global !== 'undefined' && global !== null ? global._ : undefined)) != null ? left : require('lodash');  // rely on lodash existing, since it busts CodeCombat to browserify it--TODO

const S = require('esprima').Syntax;

const ranges = require('./ranges');

const statements = [S.EmptyStatement, S.ExpressionStatement, S.BreakStatement, S.ContinueStatement, S.DebuggerStatement, S.DoWhileStatement, S.ForStatement, S.FunctionDeclaration, S.ClassDeclaration, S.IfStatement, S.ReturnStatement, S.SwitchStatement, S.ThrowStatement, S.TryStatement, S.VariableStatement, S.WhileStatement, S.WithStatement, S.VariableDeclaration];

const getParents = function(node) {
  const parents = [];
  while (node.parent) {
    parents.push(node = node.parent);
  }
  return parents;
};

const getParentsOfTypes = (node, types) => _.filter(getParents(node), elem => Array.from(types).includes(elem.type));

const getFunctionNestingLevel = node => getParentsOfTypes(node, [S.FunctionExpression]).length;

const getImmediateParentOfType = function(node, type) {
  while (node) {
    if (node.type === type) { return node; }
    node = node.parent;
  }
};


//######### Before JS_WALA Normalization ##########

// Original node range preservation.
// 1. Make a many-to-one mapping of normalized nodes to original nodes based on the original ranges, which are unique except for the outer Program wrapper.
// 2. When we generate the normalizedCode, we can also create a source map.
// 3. A postNormalizationTransform can then get the original ranges for each node by going through the source map to our normalized mapping to our original node ranges.
// 4. Instrumentation can then include the original ranges and node source in the saved flow state.
module.exports.makeGatherNodeRanges = (makeGatherNodeRanges = (nodeRanges, code, codePrefix) => (function(node) {
  if (!node.range) { return; }
  node.originalRange = ranges.offsetsToRange(node.range[0], node.range[1], code, codePrefix);

  if (node.source) {
    node.originalSource = node.source();
  }

  return nodeRanges.push(node);
}));

// Making
module.exports.makeCheckThisKeywords = (makeCheckThisKeywords = (globals, varNames, language, problemContext) => (function(node) {
  if (node.type === S.VariableDeclarator) {
    return varNames[node.id.name] = true;
  } else if (node.type === S.AssignmentExpression) {
    return varNames[node.left.name] = true;
  } else if ((node.type === S.FunctionDeclaration) || (node.type === S.FunctionExpression)) {// and node.parent.type isnt S.Program
    if (node.id != null) { varNames[node.id.name] = true; }
    return (() => {
      const result = [];
      for (var param of Array.from(node.params)) {           result.push(varNames[param.name] = true);
      }
      return result;
    })();
  } else if (node.type === S.CallExpression) {
    // TODO: false negative when user method call precedes function declaration
    let v = node;
    while ([S.CallExpression, S.MemberExpression].includes(v.type)) {
      v = (v.object != null) ? v.object : v.callee;
    }
    v = v.name;
    if (v && !varNames[v] && !(Array.from(globals).includes(v))) {
      let range;
      if (!problemContext) { return; }   // If we don't know what properties are available, don't create this problem.
      // Probably MissingThis, but let's check if we're recursively calling an inner function from itself first.
      for (var p of Array.from(getParentsOfTypes(node, [S.FunctionDeclaration, S.FunctionExpression, S.VariableDeclarator, S.AssignmentExpression]))) {
        if (p.id != null) { varNames[p.id.name] = true; }
        if (p.left != null) { varNames[p.left.name] = true; }
        if (p.params != null) { for (var param of Array.from(p.params)) { varNames[param.name] = true; } }
        if (varNames[v] === true) { return; }
      }
      if (/\$$/.test(v)) { return; }  // accum$ in CoffeeScript Redux isn't handled properly
      if (((problemContext != null ? problemContext.thisMethods : undefined) != null) && !Array.from(problemContext.thisMethods).includes(v)) { return; }
      // TODO: '@' in CoffeeScript isn't really a keyword
      const message = `Missing \`hero\` keyword; should be \`${language.heroValueAccess}${v}\`.`;
      const hint = `There is no function \`${v}\`, but \`hero\` has a method \`${v}\`.`;
      if (node.originalRange) {
        range = language.removeWrappedIndent([node.originalRange.start, node.originalRange.end]);
      }
      const problem = this.createUserCodeProblem({type: 'transpile', reporter: 'aether', kind: 'MissingThis', message, hint, range});  // TODO: code/codePrefix?
      return this.addProblem(problem);
    }
  }
}));

module.exports.makeCheckIncompleteMembers = (makeCheckIncompleteMembers = (language, problemContext) => (function(node) {
  // console.log 'check incomplete members', node, node.source() if node.source().search('this.') isnt -1
  if (node.type === 'ExpressionStatement') {
    const exp = node.expression;
    if (exp.type === 'MemberExpression') {
      // Handle missing parentheses, like in:  this.moveUp;
      let hint, kind, m;
      if (exp.property.name === "IncompleteThisReference") {
        kind = 'IncompleteThis';
        m = "this.what? (Check available spells below.)";
        return hint = '';
      } else if (exp.object.source() === language.thisValue) {
        let range;
        kind = 'NoEffect';
        m = `${exp.source()} has no effect.`;
        if (((problemContext != null ? problemContext.thisMethods : undefined) != null) && Array.from(problemContext.thisMethods).includes(exp.property.name)) {
          m += ` It needs parentheses: ${exp.source()}()`;
        } else if (((problemContext != null ? problemContext.commonThisMethods : undefined) != null) && Array.from(problemContext.commonThisMethods).includes(exp.property.name)) {
          m = `${exp.source()} is not currently available.`;
        } else {
          hint = `Is it a method? Those need parentheses: ${exp.source()}()`;
        }
        if (node.originalRange) {
          range = language.removeWrappedIndent([node.originalRange.start, node.originalRange.end]);
        }
        const problem = this.createUserCodeProblem({type: 'transpile', reporter: 'aether', message: m, kind, hint, range});  // TODO: code/codePrefix?
        return this.addProblem(problem);
      }
    }
  }
}));
