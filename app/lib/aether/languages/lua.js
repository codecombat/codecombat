// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let Lua;
import Language from './language';
import ranges from '../ranges';
const parserHolder = {};

export default Lua = (function() {
  Lua = class Lua extends Language {
    static initClass() {
      this.prototype.name = 'Lua';
      this.prototype.id = 'lua';
      this.prototype.parserID = 'lua2js';
      this.prototype.heroValueAccess = 'hero:';
    }

    constructor() {
      super(...arguments);
      this.fidMap = {};
    }

    obviouslyCannotTranspile(rawCode) {
      return false;
    }

    callParser(code, loose) {
      const ast = parserHolder.lua2js.parse(code, {loose, forceVar: false, decorateLuaObjects: true, luaCalls: true, luaOperators: true, encloseWithFunctions: false });
      return ast;
    }


    // Return an array of problems detected during linting.
    lint(rawCode, aether) {
      let ast;
      const lintProblems = [];

      try {
        ast = this.callParser(rawCode, true);
      } catch (e) {
        return [];
        return [aether.createUserCodeProblem({type: 'transpile', reporter: 'lua2js', error: e, code:rawCode, codePrefix: ""})];
      }
      for (var error of Array.from(ast.errors)) {
        var rng = ranges.offsetsToRange(error.range[0], error.range[1], rawCode, '');
        lintProblems.push(aether.createUserCodeProblem({type: 'transpile', reporter: 'lua2js', message: error.msg, code: rawCode, codePrefix: "", range: [rng.start, rng.end]}));
      }

      return lintProblems;
    }

    usesFunctionWrapping() { return false; }

    wrapResult(ast, name, params) {
      ast.body.unshift({"type": "VariableDeclaration","declarations": [
           { "type": "VariableDeclarator", "id": {"type": "Identifier", "name": "self" },"init": {"type": "ThisExpression"} }
        ],"kind": "var", "userCode": false});
      return ast;
    }

    parse(code, aether) {
      const ast = Lua.prototype.wrapResult((Lua.prototype.callParser(code, false)), aether.options.functionName, aether.options.functionParameters);
      return ast;
    }


    parseDammit(code, aether) {
      try {
        const ast = Lua.prototype.wrapResult((Lua.prototype.callParser(code, true)), aether.options.functionName, aether.options.functionParameters);
        return ast;
      } catch (error) {
        return {"type": {"BlockStatement": {body:[{type: "EmptyStatement"}]}}};
      }
    }
  };
  Lua.initClass();
  return Lua;
})();

