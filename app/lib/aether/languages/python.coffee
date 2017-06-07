_ = window?._ ? self?._ ? global?._ ? require 'lodash'  # rely on lodash existing, since it busts CodeCombat to browserify it--TODO

parserHolder = {}
traversal = require '../traversal'
Language = require './language'

module.exports = class Python extends Language
  name: 'Python'
  id: 'python'
  parserID: 'filbert'
  thisValue: 'self'
  thisValueAccess: 'self.'
  heroValueAccess: 'hero.'
  wrappedCodeIndentLen: 4

  constructor: ->
    super arguments...
    @indent = Array(@wrappedCodeIndentLen + 1).join ' '
    unless parserHolder.parser?.pythonRuntime?
      parserHolder.parser = {}
     
    @runtimeGlobals =
      __pythonRuntime: parserHolder.parser.pythonRuntime

  hasChangedASTs: (a, b) ->
    try
      [aAST, bAST] = [null, null]
      options = {locations: false, ranges: false}
      aAST = parserHolder.parserLoose.parse_dammit a, options
      bAST = parserHolder.parserLoose.parse_dammit b, options
      unless aAST and bAST
        return true
      return not _.isEqual(aAST, bAST)
    catch error
      return true


  # Return an array of UserCodeProblems detected during linting.
  lint: (rawCode, aether) ->
    problems = []

    try
      ast = parserHolder.parser.parse rawCode, locations: true, ranges: true, allowReturnOutsideFunction: true

      # Check for empty loop
      traversal.walkASTCorrect ast, (node) =>
        return unless node.type is "WhileStatement"
        return unless node.body.body.length is 0
        # Craft an warning for empty loop
        problems.push
          type: 'transpile'
          reporter: 'aether'
          level: 'warning'
          message: "Empty loop. Put 4 spaces in front of statements inside loops."
          range: [
              ofs: node.range[0]
              row: node.loc.start.line - 1
              col: node.loc.start.column
            ,
              ofs: node.range[1]
              row: node.loc.end.line - 1
              col: node.loc.end.column
          ]

      # Check for empty if
      if problems.length is 0
        traversal.walkASTCorrect ast, (node) =>
          return unless node.type is "IfStatement"
          return unless node.consequent.body.length is 0
          # Craft an warning for empty loop
          problems.push
            type: 'transpile'
            reporter: 'aether'
            level: 'warning'
            # TODO: Try 'belong to' instead of 'inside' if players still have problems
            message: "Empty if statement. Put 4 spaces in front of statements inside the if statement."
            range: [
                ofs: node.range[0]
                row: node.loc.start.line - 1
                col: node.loc.start.column
              ,
                ofs: node.range[1]
                row: node.loc.end.line - 1
                col: node.loc.end.column
            ]

    catch error

    problems

  usesFunctionWrapping: () -> false

  # Using a third-party parser, produce an AST in the standardized Mozilla format.
  parse: (code, aether) ->
    ast = parserHolder.parser.parse code, {locations: false, ranges: true, allowReturnOutsideFunction: true}
    selfToThis ast
    ast

  parseDammit: (code, aether) ->
    try
      ast = parserHolder.parserLoose.parse_dammit code, {locations: false, ranges: true}
      selfToThis ast
    catch error
      ast = {type: "Program", body:[{"type": "EmptyStatement"}]}
    ast

  convertToNativeType: (obj) ->
    parserHolder.parser.pythonRuntime.utils.convertToList(obj) if not obj?._isPython and _.isArray obj
    parserHolder.parser.pythonRuntime.utils.convertToDict(obj) if not obj?._isPython and _.isObject obj
    obj

  cloneObj: (obj, cloneFn=(o) -> o) ->
    if _.isArray obj
      result = new parserHolder.parser.pythonRuntime.objects.list()
      result.append(cloneFn v) for v in obj
    else if _.isObject obj
      result = new parserHolder.parser.pythonRuntime.objects.dict()
      result[k] = cloneFn v for k, v of obj
    else
      result = cloneFn obj
    result

  selfToThis = (ast) ->
    ast.body.unshift {"type": "VariableDeclaration","declarations": [{ "type": "VariableDeclarator", "id": {"type": "Identifier", "name": "self" },"init": {"type": "ThisExpression"} }],"kind": "var", "userCode": false}  # var self = this;
    ast

  setupInterpreter: (esper) ->
    realm = esper.realm
    realm.options.linkValueCallReturnValueWrapper = (value) ->
      ArrayPrototype = realm.ArrayPrototype

      return value unless value.jsTypeName is 'object'

      if value.clazz is 'Array'
        defineProperties = realm.Object.getImmediate('defineProperties')
        listPropertyDescriptor = realm.globalScope.get('__pythonRuntime').getImmediate('utils').getImmediate('listPropertyDescriptor')

        gen = defineProperties.call realm.Object, [value, listPropertyDescriptor], realm.globalScope
        it = gen.next()
        while not it.done
          it = gen.next()

      return value
