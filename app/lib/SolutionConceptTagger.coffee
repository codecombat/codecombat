concepts = require 'schemas/concepts'

module.exports = TagSolution = (solution) ->
  code = solution.source
  engine = new esper.Engine()
  engine.load(code)
  ast = engine.evaluator.ast
  result = []
  for key of concepts
    tkn = concepts[key].tagger
    continue unless tkn
    if typeof tkn is 'function'
      result.push concepts[key].concept if tkn(ast)
    else
      result.push concepts[key].concept if ast.find(tkn).length > 0
   
  console.log result
  result
