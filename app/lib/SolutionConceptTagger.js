/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let TagSolution;
module.exports = (TagSolution = function({source, ast, language}, concepts) {
  const engine = new esper.Engine();
  if (source) {
    engine.load(source);
  } else if (ast) {
    engine.loadAST(ast);
  }
  const esperAST = engine.evaluator.ast;
  if (language === 'python') {
    // remove the first variable assignment, which appears to be added by skulpty in the transpilation
    esperAST.body.shift();
  }
  const result = [];
  concepts.each(function(concept) {
    let tkn;
    const tagger = concept.get('tagger');
    const taggerFunction = concept.get('taggerFunction');
    try {
      tkn = tagger ? tagger : taggerFunction ? (new Function(`return ${taggerFunction}`))() : null;
    } catch (e) {
      console.error('Error parsing tagger function for concept', concept.get('key'), e);
    }
    if (!tkn) { return; }
    const name = concept.get('key');
    if (typeof tkn === 'function') {
      if (tkn(esperAST)) { return result.push(name); }
    } else {
      if (esperAST.find(tkn).length > 0) { return result.push(name); }
    }
  });
  return result;
});
