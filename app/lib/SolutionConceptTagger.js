// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let TagSolution;
import concepts from 'schemas/concepts';

export default TagSolution = function({source, ast, language}) {
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
  for (var key in concepts) {
    var tkn = concepts[key].tagger;
    if (!tkn) { continue; }
    if (typeof tkn === 'function') {
      if (tkn(esperAST)) { result.push(concepts[key].concept); }
    } else {
      if (esperAST.find(tkn).length > 0) { result.push(concepts[key].concept); }
    }
  }
  return result;
};
