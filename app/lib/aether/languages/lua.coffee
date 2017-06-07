Language = require './language'
ranges = require '../ranges'
parserHolder = {}

module.exports = class Lua extends Language
  name: 'Lua'
  id: 'lua'
  parserID: 'lua2js'
  heroValueAccess: 'hero:'

  constructor: ->
    super arguments...
    @fidMap = {}

  obviouslyCannotTranspile: (rawCode) ->
    false

  callParser: (code, loose) ->
    ast = parserHolder.lua2js.parse code, {loose: loose, forceVar: false, decorateLuaObjects: true, luaCalls: true, luaOperators: true, encloseWithFunctions: false }
    ast


  # Return an array of problems detected during linting.
  lint: (rawCode, aether) ->
    lintProblems = []

    try
      ast = @callParser rawCode, true
    catch e
      return []
      return [aether.createUserCodeProblem type: 'transpile', reporter: 'lua2js', error: e, code:rawCode, codePrefix: ""]
    for error in ast.errors
      rng = ranges.offsetsToRange(error.range[0], error.range[1], rawCode, '')
      lintProblems.push aether.createUserCodeProblem type: 'transpile', reporter: 'lua2js', message: error.msg, code: rawCode, codePrefix: "", range: [rng.start, rng.end]

    lintProblems

  usesFunctionWrapping: () -> false

  wrapResult: (ast, name, params) ->
    ast.body.unshift {"type": "VariableDeclaration","declarations": [
         { "type": "VariableDeclarator", "id": {"type": "Identifier", "name": "self" },"init": {"type": "ThisExpression"} }
      ],"kind": "var", "userCode": false}
    ast

  parse: (code, aether) ->
    ast = Lua.prototype.wrapResult (Lua.prototype.callParser code, false), aether.options.functionName, aether.options.functionParameters
    ast


  parseDammit: (code, aether) ->
    try
      ast = Lua.prototype.wrapResult (Lua.prototype.callParser code, true), aether.options.functionName, aether.options.functionParameters
      return ast
    catch error
      return {"type": "BlockStatement": body:[{type: "EmptyStatement"}]}

