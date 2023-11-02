/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let Language;
const ranges = require('../ranges');

module.exports = (Language = (function() {
  Language = class Language {
    static initClass() {
      this.prototype.name = 'Abstract Language';  // Display name of the programming language
      this.prototype.id = 'abstract-language';  // Snake-case id of the programming language
      this.prototype.parserID = 'abstract-parser';
      this.prototype.runtimeGlobals = {};  // Like {__lua: require('lua2js').runtime}
      this.prototype.thisValue = 'this'; // E.g. in Python it is 'self'
      this.prototype.thisValueAccess = 'this.'; // E.g. in Python it is 'self.'
      this.prototype.heroValueAccess = 'hero.';
      this.prototype.wrappedCodeIndentLen = 0;
    }

    constructor() {}

    // Return true if we can very quickly identify a syntax error.
    obviouslyCannotTranspile(rawCode) {
      return false;
    }

    // Return true if there are significant (non-whitespace) differences in the ASTs for a and b.
    hasChangedASTs(a, b) {
      return true;
    }

    // Return true if a and b have the same number of lines after we strip trailing comments and whitespace.
    hasChangedLineNumbers(a, b) {
      // This implementation will work for languages with comments starting with //
      // TODO: handle /* */
      const trimRight = 
      !String.prototype.trimRight ?
        (String.prototype.trimRight = function() { return String(this).replace(/\s\s*$/, ''); }) : undefined;
      a = a.replace(/^[ \t]+\/\/.*/g, '').trimRight();
      b = b.replace(/^[ \t]+\/\/.*/g, '').trimRight();
      return a.split('\n').length !== b.split('\n').length;
    }

    // Return an array of UserCodeProblems detected during linting.
    lint(rawCode, aether) {
      return [].concat(this.lintUncalledMethods(rawCode, aether)); // check uncalled-methods for every language
    }

    lintUncalledMethods(rawCode, aether) {
      let match;
      if (!(match = rawCode.match(/^ *(hero[\.|:][^\d\W]\w*)(;?)$/mi))) { return []; }

      const message = `i18n::esper.do_nothing_without_parentheses::${JSON.stringify({code: match[0]})}`;
      const hint = `i18n::esper.missing_parentheses::${JSON.stringify({suggestion: match[1] + "()" + match[2]})}`;
      const problem = {
        type: 'transpile',
        reporter: 'aether',
        level: 'warning',
        message,
        hint,
        range: [
          ranges.offsetToPos(match.index, rawCode, ''),
          ranges.offsetToPos(match.index + match[0].length, rawCode, '')
        ]
      };
      return [problem];
    }

    // Return a beautified representation of the code (cleaning up indentation, etc.)
    beautify(rawCode, aether) {
      return rawCode;
    }

    // Wrap the user code in a function. Store @wrappedCodePrefix and @wrappedCodeSuffix.
    wrap(rawCode, aether) {
      if (this.wrappedCodePrefix == null) { this.wrappedCodePrefix = ''; }
      if (this.wrappedCodeSuffix == null) { this.wrappedCodeSuffix = ''; }
      return this.wrappedCodePrefix + rawCode + this.wrappedCodeSuffix;
    }

    // Languages requiring extra indent in their wrapped code may need to remove it from ranges
    // E.g. Python
    removeWrappedIndent(range) {
      return range;
    }

    // Hacky McHack step for things we can't easily change via AST transforms (which preserve statement ranges).
    // TODO: Should probably refactor and get rid of this soon.
    hackCommonMistakes(rawCode, aether) {
      return rawCode;
    }

    // Using a third-party parser, produce an AST in the standardized Mozilla format.
    parse(code, aether) {
      throw new Error(`parse() not implemented for ${this.id}.`);
    }

    // Optional: if parseDammit() is implemented, then if parse() throws an error, we'll try again using parseDammit().
    // Useful for parsing incomplete code as it is being written without giving up.
    // This should never throw an error and should always return some sort of AST, even if incomplete or empty.
    //parseDammit: (code, aether) ->

    // Convert obj to a language-specific type
    // E.g. if obj is an Array and language is Python, return a Python list
    convertToNativeType(obj) {
      return obj;
    }

    usesFunctionWrapping() {
      return true;
    }

    cloneObj(obj, cloneFn) {
      // Clone obj to a language-specific equivalent object
      // E.g. if obj is an Array and language is Python, we want a new Python list instead of a JavaScript Array.
      // Use cloneFn for children and simple types
      let result;
      let v;
      if (cloneFn == null) { cloneFn = o => o; }
      if (_.isArray(obj)) {
        result = ((() => {
          const result1 = [];
          for (v of Array.from(obj)) {             result1.push(cloneFn(v));
          }
          return result1;
        })());
      } else if (_.isObject(obj)) {
        result = {};
        for (var k in obj) { v = obj[k]; result[k] = cloneFn(v); }
      } else {
        result = cloneFn(obj);
      }
      return result;
    }

    rewriteFunctionID(fid) {
      return fid;
    }

    setupInterpreter(esper) {}
  };
  Language.initClass();
  return Language;
})());
