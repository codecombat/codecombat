concepts = require 'schemas/concepts'

module.exports = TagSolution = ({source, ast, language}) ->
  engine = new esper.Engine()
  if source
    engine.load(source)
  else if ast
    engine.loadAST(ast)
  esperAST = engine.evaluator.ast
  if language is 'python'
    # remove the first variable assignment, which appears to be added by skulpty in the transpilation
    esperAST.body.shift() 
  result = []
  for key of concepts
    tkn = concepts[key].tagger
    continue unless tkn
    if typeof tkn is 'function'
      result.push concepts[key].concept if tkn(esperAST)
    else
      result.push concepts[key].concept if esperAST.find(tkn).length > 0
  result
