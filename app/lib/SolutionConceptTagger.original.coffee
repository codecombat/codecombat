module.exports = TagSolution = ({source, ast, language}, concepts) ->
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
  concepts.each (concept) ->
    tagger = concept.get('tagger')
    taggerFunction = concept.get('taggerFunction')
    try
      tkn = if tagger then tagger else if taggerFunction then (new Function("return #{taggerFunction}"))() else null
    catch e
      console.error 'Error parsing tagger function for concept', concept.get('key'), e
    return unless tkn
    name = concept.get('key')
    if typeof tkn is 'function'
      result.push name if tkn(esperAST)
    else
      result.push name if esperAST.find(tkn).length > 0
  result
