_ = window?._ ? self?._ ? global?._ ? require 'lodash'  # rely on lodash existing, since it busts CodeCombat to browserify it--TODO

S = require('esprima').Syntax

ranges = require './ranges'

statements = [S.EmptyStatement, S.ExpressionStatement, S.BreakStatement, S.ContinueStatement, S.DebuggerStatement, S.DoWhileStatement, S.ForStatement, S.FunctionDeclaration, S.ClassDeclaration, S.IfStatement, S.ReturnStatement, S.SwitchStatement, S.ThrowStatement, S.TryStatement, S.VariableStatement, S.WhileStatement, S.WithStatement, S.VariableDeclaration]

getParents = (node) ->
  parents = []
  while node.parent
    parents.push node = node.parent
  parents

getParentsOfTypes = (node, types) ->
  _.filter getParents(node), (elem) -> elem.type in types

getFunctionNestingLevel = (node) ->
  getParentsOfTypes(node, [S.FunctionExpression]).length

getImmediateParentOfType = (node, type) ->
  while node
    return node if node.type is type
    node = node.parent


########## Before JS_WALA Normalization ##########

# Original node range preservation.
# 1. Make a many-to-one mapping of normalized nodes to original nodes based on the original ranges, which are unique except for the outer Program wrapper.
# 2. When we generate the normalizedCode, we can also create a source map.
# 3. A postNormalizationTransform can then get the original ranges for each node by going through the source map to our normalized mapping to our original node ranges.
# 4. Instrumentation can then include the original ranges and node source in the saved flow state.
module.exports.makeGatherNodeRanges = makeGatherNodeRanges = (nodeRanges, code, codePrefix) -> (node) ->
  return unless node.range
  node.originalRange = ranges.offsetsToRange node.range[0], node.range[1], code, codePrefix

  if node.source
    node.originalSource = node.source()

  nodeRanges.push node

# Making
module.exports.makeCheckThisKeywords = makeCheckThisKeywords = (globals, varNames, language, problemContext) ->
  return (node) ->
    if node.type is S.VariableDeclarator
      varNames[node.id.name] = true
    else if node.type is S.AssignmentExpression
      varNames[node.left.name] = true
    else if node.type is S.FunctionDeclaration or node.type is S.FunctionExpression# and node.parent.type isnt S.Program
      varNames[node.id.name] = true if node.id?
      varNames[param.name] = true for param in node.params
    else if node.type is S.CallExpression
      # TODO: false negative when user method call precedes function declaration
      v = node
      while v.type in [S.CallExpression, S.MemberExpression]
        v = if v.object? then v.object else v.callee
      v = v.name
      if v and not varNames[v] and not (v in globals)
        return unless problemContext   # If we don't know what properties are available, don't create this problem.
        # Probably MissingThis, but let's check if we're recursively calling an inner function from itself first.
        for p in getParentsOfTypes node, [S.FunctionDeclaration, S.FunctionExpression, S.VariableDeclarator, S.AssignmentExpression]
          varNames[p.id.name] = true if p.id?
          varNames[p.left.name] = true if p.left?
          varNames[param.name] = true for param in p.params if p.params?
          return if varNames[v] is true
        return if /\$$/.test v  # accum$ in CoffeeScript Redux isn't handled properly
        return if problemContext?.thisMethods? and v not in problemContext.thisMethods
        # TODO: '@' in CoffeeScript isn't really a keyword
        message = "Missing `hero` keyword; should be `#{language.heroValueAccess}#{v}`."
        hint = "There is no function `#{v}`, but `hero` has a method `#{v}`."
        if node.originalRange
          range = language.removeWrappedIndent [node.originalRange.start, node.originalRange.end]
        problem = @createUserCodeProblem type: 'transpile', reporter: 'aether', kind: 'MissingThis', message: message, hint: hint, range: range  # TODO: code/codePrefix?
        @addProblem problem

module.exports.makeCheckIncompleteMembers = makeCheckIncompleteMembers = (language, problemContext) ->
  return (node) ->
    # console.log 'check incomplete members', node, node.source() if node.source().search('this.') isnt -1
    if node.type is 'ExpressionStatement'
      exp = node.expression
      if exp.type is 'MemberExpression'
        # Handle missing parentheses, like in:  this.moveUp;
        if exp.property.name is "IncompleteThisReference"
          kind = 'IncompleteThis'
          m = "this.what? (Check available spells below.)"
          hint = ''
        else if exp.object.source() is language.thisValue
          kind = 'NoEffect'
          m = "#{exp.source()} has no effect."
          if problemContext?.thisMethods? and exp.property.name in problemContext.thisMethods
            m += " It needs parentheses: #{exp.source()}()"
          else if problemContext?.commonThisMethods? and exp.property.name in problemContext.commonThisMethods
            m = "#{exp.source()} is not currently available."
          else
            hint = "Is it a method? Those need parentheses: #{exp.source()}()"
          if node.originalRange
            range = language.removeWrappedIndent [node.originalRange.start, node.originalRange.end]
          problem = @createUserCodeProblem type: 'transpile', reporter: 'aether', message: m, kind: kind, hint: hint, range: range  # TODO: code/codePrefix?
          @addProblem problem
