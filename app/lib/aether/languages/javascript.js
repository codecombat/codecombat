// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS104: Avoid inline assignments
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let JavaScript, left, left1;
const _ = (left = (left1 = (typeof window !== 'undefined' && window !== null ? window._ : undefined) != null ? (typeof window !== 'undefined' && window !== null ? window._ : undefined) : (typeof self !== 'undefined' && self !== null ? self._ : undefined)) != null ? left1 : (typeof global !== 'undefined' && global !== null ? global._ : undefined)) != null ? left : require('lodash');  // rely on lodash existing, since it busts CodeCombat to browserify it--TODO

const jshintHolder = {};
const acorn_loose = require('acorn-loose');
const escodegen = require('escodegen');

const Language = require('./language');
const traversal = require('../traversal');

module.exports = (JavaScript = (function() {
  JavaScript = class JavaScript extends Language {
    static initClass() {
      this.prototype.name = 'JavaScript';
      this.prototype.id = 'javascript';
      this.prototype.parserID = 'esprima';
      this.prototype.thisValue = 'this';
      this.prototype.thisValueAccess = 'this.';
      this.prototype.heroValueAccess = 'hero.';
    }

    constructor() {
      super(...arguments);
      const { JSHINT } = require('jshint');
      if (jshintHolder.jshint == null) { jshintHolder.jshint = JSHINT; }
    }

    // Return true if we can very quickly identify a syntax error.
    obviouslyCannotTranspile(rawCode) {
      try {
        // Inspired by ACE: https://github.com/ajaxorg/ace/blob/master/lib/ace/mode/javascript_worker.js
        eval("'use strict;'\nthrow 0;" + rawCode);  // evaluated code can only create variables in this function
      } catch (e) {
        if (e !== 0) { return true; }
      }
      return false;
    }

    // Return true if there are significant (non-whitespace) differences in the ASTs for a and b.
    hasChangedASTs(a, b) {
      // We try first with Esprima, to be precise, then with acorn_loose if that doesn't work.
      let options = {loc: false, range: false, comment: false, tolerant: true};
      let [aAST, bAST] = Array.from([null, null]);
      try { aAST = esprima.parse(a, options); } catch (error) {}
      try { bAST = esprima.parse(b, options); } catch (error1) {}
      if ((!aAST || !bAST) && (aAST || bAST)) { return true; }
      if (aAST && bAST) {
        if ((aAST.errors != null ? aAST.errors : []).length !== (bAST.errors != null ? bAST.errors : []).length) { return true; }
        return !_.isEqual(aAST.body, bAST.body);
      }
      // Esprima couldn't parse either ASTs, so let's fall back to acorn_loose
      options = {locations: false, tabSize: 4, ecmaVersion: 5};
      aAST = acorn_loose.parse(a, options);
      bAST = acorn_loose.parse(b, options);
      if (!aAST || !bAST) {
        console.log(`Couldn't even loosely parse; are you sure ${a} and ${b} are ${this.name}?`);
        return true;
      }
      // acorn_loose annoyingly puts start/end in every node; we'll remove before comparing
      const removeLocations = function(node) { if (node) { return node.start = (node.end = null); } };
      traversal.walkAST(aAST, removeLocations);
      traversal.walkAST(bAST, removeLocations);
      return !_.isEqual(aAST, bAST);
    }


    // Return an array of problems detected during linting.
    lint(rawCode, aether) {
      let e;
      const lintProblems = super.lint(rawCode, aether);
      try {
        if (btoa(atob(rawCode)) === rawCode) {
          return []; // dont lint other session
        }
      } catch (error1) {
        e = error1;
        null; // do nothing
      }
      // return lintProblems unless jshintHolder.jshint
      const wrappedCode = this.wrap(rawCode, aether);

      // Run it through JSHint first, because that doesn't rely on Esprima
      // See also how ACE does it: https://github.com/ajaxorg/ace/blob/master/lib/ace/mode/javascript_worker.js
      // TODO: make JSHint stop providing these globals somehow; the below doesn't work
      const jshintOptions = {browser: false, couch: false, devel: false, dojo: false, jquery: false, mootools: false, node: false, nonstandard: false, phantom: false, prototypejs: false, rhino: false, worker: false, wsh: false, yui: false, iterator: true, esnext: true};
      var jshintGlobals = _.zipObject(jshintGlobals, (Array.from(aether.allGlobals).map((g) => false)));  // JSHint expects {key: writable} globals
      // Doesn't work; can't find a way to skip warnings from JSHint programmatic options instead of in code comments.
      //for problemID, problem of @originalOptions.problems when problem.level is 'ignore' and /jshint/.test problemID
      //  console.log 'gotta ignore', problem, '-' + problemID.replace('jshint_', '')
      //  jshintOptions['-' + problemID.replace('jshint_', '')] = true
      try {
        const jshintSuccess = jshintHolder.jshint(wrappedCode, jshintOptions, jshintGlobals);
      } catch (error2) {
        e = error2;
        console.warn("JSHint died with error", e);  //, "on code\n", wrappedCode
      }
      for (var error of Array.from(jshintHolder.jshint.errors)) {
        lintProblems.push(aether.createUserCodeProblem({type: 'transpile', reporter: 'jshint', error, code: wrappedCode, codePrefix: this.wrappedCodePrefix}));
      }

      // Check for stray semi-colon on 1st line of if statement
      // E.g. "if (parsely);"
      // TODO: Does not handle stray semi-colons on following lines: "if (parsely)\n;"
      if (_.isEmpty(lintProblems)) {
        const lines = rawCode.split(/\r\n|[\n\r\u2028\u2029]/g);
        let offset = 0;
        for (let row = 0; row < lines.length; row++) {
          var line = lines[row];
          if (/^\s*if /.test(line)) {
            // Have an if statement
            var firstParen;
            if ((firstParen = line.indexOf('(')) >= 0) {
              var i;
              var parenCount = 1;
              var iterable = line.slice(firstParen + 1, +line.length + 1 || undefined);
              for (i = 0; i < iterable.length; i++) {
                var c = iterable[i];
                if (c === '(') { parenCount++; }
                if (c === ')') { parenCount--; }
                if (parenCount === 0) { break; }
              }
              // parenCount should be zero at the end of the if (test)
              i += firstParen + 1 + 1;
              if ((parenCount === 0) && /^[ \t]*;/.test(line.slice(i, +line.length + 1 || undefined))) {
                // And it's followed immediately by a semi-colon
                var firstSemiColon = line.indexOf(';');
                lintProblems.push({
                  type: 'transpile',
                  reporter: 'aether',
                  level: 'warning',
                  message: "Don't put a ';' after an if statement.",
                  range: [{
                      ofs: offset + firstSemiColon,
                      row,
                      col: firstSemiColon
                    }
                    , {
                      ofs: offset + firstSemiColon + 1,
                      row,
                      col: firstSemiColon + 1
                    }
                  ]});
                break;
              }
            }
          }
          // TODO: this may be off by 1*row if linebreak was \r\n
          offset += line.length + 1;
        }
      }
      return lintProblems;
    }

    // Return a beautified representation of the code (cleaning up indentation, etc.)
    beautify(rawCode, aether) {
      let ast;
      try {
        ast = esprima.parse(rawCode, {range: true, tokens: true, comment: true, tolerant: true});
        ast = escodegen.attachComments(ast, ast.comments, ast.tokens);
      } catch (e) {
        console.log('got error beautifying', e);
        ast = acorn_loose.parse(rawCode, {tabSize: 4, ecmaVersion: 5});
      }
      const beautified = escodegen.generate(ast, {comment: true, parse: esprima.parse});
      return beautified;
    }

    usesFunctionWrapping() { return false; }

    // Hacky McHack step for things we can't easily change via AST transforms (which preserve statement ranges).
    // TODO: Should probably refactor and get rid of this soon.
    hackCommonMistakes(code, aether) {
      // Stop standalone this.\n from failing on the next weird line
      code = code.replace(/\n\s*this\.\s*?\n/g, "\nthis.IncompleteThisReference;");
      // If we wanted to do it just when it would hit the ending } but allow multiline this refs:
      //code = code.replace /this.(\s+})$/, "this.IncompleteThisReference;$1"
      return code;
    }

    // Using a third-party parser, produce an AST in the standardized Mozilla format.
    parse(code, aether) {
      // loc: https://github.com/codecombat/aether/issues/71
      const ast = esprima.parse(code, {range: true, loc: true, tolerant: true});
      let errors = [];
      if (ast.errors) {
        errors = (Array.from(ast.errors).filter((x) => x.description !== 'Illegal return statement'));
        delete ast.errors;
      }

      if (errors[0]) { throw errors[0]; }
      return ast;
    }

    // Optional: if parseDammit() is implemented, then if parse() throws an error, we'll try again using parseDammit().
    // Useful for parsing incomplete code as it is being written without giving up.
    // This should never throw an error and should always return some sort of AST, even if incomplete or empty.
    parseDammit(code, aether) {
      const ast = acorn_loose.parse(code, {locations: true, tabSize: 4, ecmaVersion: 5});

      if ((ast != null) && (ast.body.length !== 1)) {
        ast.body = ast.body.slice(0,0);
      }
      ast;

      // Esprima uses "range", but acorn_loose only has "locations"
      const lines = code.replace(/\n/g, '\n空').split('空');  // split while preserving newlines
      const posToOffset = pos => _.reduce(lines.slice(0, pos.line - 1), ((sum, line) => sum + line.length), 0) + pos.column;
        // lines are 1-indexed, and I think columns are 0-indexed, but should verify
      const locToRange = loc => [posToOffset(loc.start), posToOffset(loc.end)];
      const fixNodeRange = function(node) {
        // Sometimes you can get an if-statement with "alternate": null
        if (node && node.loc) { return node.range = locToRange(node.loc); }
      };
      traversal.walkAST(ast, fixNodeRange);

      return ast;
    }
  };
  JavaScript.initClass();
  return JavaScript;
})());
