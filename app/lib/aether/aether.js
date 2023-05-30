// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let Aether, self;
if ((typeof window !== 'undefined' && window !== null) && (self == null)) { self = window; }
if ((typeof global !== 'undefined' && global !== null) && (self == null)) { self = global; }
if (self.self == null) { self.self = self; }

import esprima from 'esprima';  // getting our Esprima Harmony
import defaults from './defaults';
import problems from './problems';
import execution from './execution';
import traversal from './traversal';
import transforms from './transforms';
import protectBuiltins from './protectBuiltins';
import optionsValidator from './validators/options';
import languages from './languages/languages';
import interpreter from './interpreter';

export default Aether = (function() {
  Aether = class Aether {
    static initClass() {
      this.execution = execution;
      this.addGlobal = protectBuiltins.addGlobal;  // Call instance method version after instance creation to update existing global list
      this.replaceBuiltin = protectBuiltins.replaceBuiltin;
      this.globals = protectBuiltins.addedGlobals;
  
      // Current call depth
      this.prototype.depth = 0;
  
      // Create a standard Aether problem object out of some sort of transpile or runtime problem.
      this.prototype.createUserCodeProblem = problems.createUserCodeProblem;
    }

    getAddedGlobals() {
      return protectBuiltins.addedGlobals;
    }

    addGlobal(name, value) {
      // Call class method version before instance creation to instantiate global list
      if (this.esperEngine != null) {
        return this.esperEngine.addGlobal(name, value);
      }
    }

    constructor(options) {
      if (options == null) { options = {}; }
      const validationResults = optionsValidator(options);
      if (!validationResults.valid) {
        throw new Error("Aether options are invalid: " + JSON.stringify(validationResults.errors, null, 4));
      }

      // Save our original options for recreating this Aether later.
      this.originalOptions = _.cloneDeep(options);  // TODO: slow

      // Merge the given options with the defaults.
      const defaultsCopy = _.cloneDeep(defaults);
      this.options = _.merge(defaultsCopy, options);

      this.setLanguage(this.options.language);
      this.allGlobals = this.options.globals.concat(protectBuiltins.builtinNames, Object.keys(this.language.runtimeGlobals));  // After setLanguage, which can add globals.
      //if statementStack[0]?
      //  rng = statementStack[0].originalRange
      //  aether.lastStatementRange = [rng.start, rng.end] if rng

      Object.defineProperty(this, 'lastStatementRange', {
        get() {
          const rng = __guard__(__guard__(this.esperEngine != null ? this.esperEngine.evaluator : undefined, x1 => x1.lastASTNodeProcessed), x => x.originalRange);
          if (rng) { return [rng.start, rng.end]; }
        }
      }
      );
    }

    // Language can be changed after construction. (It will reset Aether's state.)
    setLanguage(language) {
      if (this.language && (this.language.id === language)) { return; }
      const validationResults = optionsValidator({language});
      if (!validationResults.valid) {
        throw new Error("New language is invalid: " + JSON.stringify(validationResults.errors, null, 4));
      }
      this.originalOptions.language = (this.options.language = language);
      this.language = new (languages[language])();
      if (this.languageJS == null) { this.languageJS = language === 'javascript' ? this.language : new languages.javascript('ES5'); }
      this.reset();
      return language;
    }

    // Resets the state of Aether, readying it for a fresh transpile.
    reset() {
      this.problems = {errors: [], warnings: [], infos: []};
      this.style = {};
      this.flow = {};
      this.metrics = {};
      return this.pure = null;
    }

    // Convert to JSON so we can pass it across web workers and HTTP requests and store it in databases and such.
    serialize() {
      return _.pick(this, ['originalOptions', 'raw', 'pure', 'problems', 'flow', 'metrics', 'style', 'ast']);
    }

    // Convert a serialized Aether instance back from JSON.
    static deserialize(serialized) {
      const aether = new Aether(serialized.originalOptions);
      for (var prop in serialized) { var val = serialized[prop]; if (prop !== "originalOptions") { aether[prop] = val; } }
      return aether;
    }

    // Performs quick heuristics to determine whether the code will run or produce compilation errors.
    // If thorough, it will perform detailed linting and return false if there are any lint errors.
    canTranspile(rawCode, thorough) {
      if (thorough == null) { thorough = false; }
      if (!rawCode) { return true; } // blank code should compile, but bypass the other steps
      if (this.language.obviouslyCannotTranspile(rawCode)) { return false; }
      if (!thorough) { return true; }
      return this.lint(rawCode, this).errors.length === 0;
    }

    // Determine whether two strings of code are significantly different.
    // If careAboutLineNumbers, we strip trailing comments and whitespace and compare line count.
    // If careAboutLint, we also lint and make sure lint problems are the same.
    hasChangedSignificantly(a, b, careAboutLineNumbers, careAboutLint) {
      if (careAboutLineNumbers == null) { careAboutLineNumbers = false; }
      if (careAboutLint == null) { careAboutLint = false; }
      a = Aether.getTokenSource(a);
      b = Aether.getTokenSource(b);
      if ((a == null) || (b == null)) { return true; }
      if (a === b) { return false; }
      if (careAboutLineNumbers && this.language.hasChangedLineNumbers(a, b)) { return true; }
      if (careAboutLint && this.hasChangedLintProblems(a, b)) { return true; }
      // If the simple tests fail, we compare abstract syntax trees for equality.
      return this.language.hasChangedASTs(a, b);
    }

    // Determine whether two strings of code produce different lint problems.
    hasChangedLintProblems(a, b) {
      let p;
      const aLintProblems = ((() => {
        const result = [];
        for (p of Array.from(this.getAllProblems(this.lint(a)))) {           result.push([p.id, p.message, p.hint]);
        }
        return result;
      })());
      const bLintProblems = ((() => {
        const result1 = [];
        for (p of Array.from(this.getAllProblems(this.lint(b)))) {           result1.push([p.id, p.message, p.hint]);
        }
        return result1;
      })());
      return !_.isEqual(aLintProblems, bLintProblems);
    }

    // Return a beautified representation of the code (cleaning up indentation, etc.)
    beautify(rawCode) {
      return this.language.beautify(rawCode, this);
    }

    // Transpile it. Even if it can't transpile, it will give syntax errors and warnings and such. Clears any old state.
    transpile(raw) {
      this.raw = raw;
      this.reset();
      const rawCode = this.raw;
      if (/^\u56E7[a-zA-Z0-9+/=]+\f$/.test(rawCode)) {
        const { Unibabel } = require('unibabel');  // Cannot be imported in Node.js context
        const token = JSON.parse(Unibabel.base64ToUtf8(rawCode.substr(1, rawCode.length-2)));
        this.raw = token.src;
        if (token.error) {
          const error = new SyntaxError(token.error.message, '', token.error.data.line);
          Object.assign(error, token.error.data);
          const problemOptions = {error, code: token.src, codePrefix: "", reporter: this.language.parserID, kind: error.index || error.id, type: 'transpile'};
          this.addProblem(this.createUserCodeProblem(problemOptions));
        } else {
          this.problems = this.lint(token.src);
          this.pure = token.src;
          this.ast = token.ast;
        }
      } else {
        if (['cpp', 'java'].includes(this.language.id)) {
          throw new Error('C++/Java code cannot be transpiled client side, needs server transpilation.');
        }
        this.problems = this.lint(rawCode);
        this.pure = this.purifyCode(rawCode);
      }
      return this.pure;
    }

    // Perform some fast static analysis (without transpiling) and find any lint problems.
    lint(rawCode) {
      const lintProblems = {errors: [], warnings: [], infos: []};
      for (var problem of Array.from(this.language.lint(rawCode, this))) { this.addProblem(problem, lintProblems); }
      return lintProblems;
    }

    // Return a ready-to-interpret function from the parsed code.
    createFunction() {
      return interpreter.createFunction(this);
    }

    // Like createFunction, but binds method to thisValue.
    createMethod(thisValue) {
      return _.bind(this.createFunction(), thisValue);
    }

    // Convenience wrapper for running the compiled function with default error handling
    run(fn, ...args) {
      let error, problem;
      try {
        if (fn == null) { fn = this.createFunction(); }
      } catch (error1) {
        error = error1;
        problem = this.createUserCodeProblem({error, code: this.raw, type: 'transpile', reporter: 'aether', aether: this});
        this.addProblem(problem);
        return;
      }
      try {
        return fn(...Array.from(args || []));
      } catch (error2) {
        error = error2;
        problem = this.createUserCodeProblem({error, code: this.raw, type: 'runtime', reporter: 'aether', aether: this});
        this.addProblem(problem);
        return;
      }
    }

    createThread(fx) {
      return interpreter.createThread(this, fx);
    }

    updateProblemContext(problemContext) {
      return this.options.problemContext = problemContext;
    }

    // Add problem to the proper level's array within the given problems object (or @problems).
    addProblem(problem, problems=null) {
      if (problem.level === "ignore") { return; }
      if (problem.message === 'Missing semicolon.') { return; } // TODO: configurable in esper instead?
      (problems != null ? problems : this.problems)[problem.level + "s"].push(problem);
      return problem;
    }

    // Return all the problems as a flat array.
    getAllProblems(problems) {
      return _.flatten(_.values((problems != null ? problems : this.problems)));
    }

    /*
      purifyCode takes raw code and returns some slightly instrumented (wrapped) code.
      TODO: Do we really wrap code anymore with esper?

      However the main function of `purifyCode` is to parse the given code into
      an Abstract Syntax Tree (AST) which is then attached to @ast.
      If parsing the code throws an error, we catch it and create a user code problem.
    */
    purifyCode(rawCode) {
      const preprocessedCode = this.language.hackCommonMistakes(rawCode, this);  // TODO: if we could somehow not change the source ranges here, that would be awesome.... but we'll probably just need to get rid of this step.
      const wrappedCode = this.language.wrap(preprocessedCode, this);

      const varNames = {};
      for (var parameter of Array.from(this.options.functionParameters)) { varNames[parameter] = true; }
      const preNormalizationTransforms = [
        transforms.makeCheckThisKeywords(this.allGlobals, varNames, this.language, this.options.problemContext),
        transforms.makeCheckIncompleteMembers(this.language, this.options.problemContext)
      ];
      try {
        this.ast = interpreter.parse(this, wrappedCode);
      } catch (error) {
        const problemOptions = {error, code: wrappedCode, codePrefix: this.language.wrappedCodePrefix, reporter: this.language.parserID, kind: error.index || error.id, type: 'transpile'};
        this.addProblem(this.createUserCodeProblem(problemOptions));
        return '';
      }

      return wrappedCode;
    }


    static getFunctionBody(func) {
      // Remove function() { ... } wrapper and any extra indentation
      let source = _.isString(func) ? func : func.toString();
      if (source.trim() === "function () {}") { return ""; }
      source = source.substring(source.indexOf('{') + 2, source.lastIndexOf('}'));  //.trim()
      const lines = source.split(/\r?\n/);
      const indent = lines.length ? lines[0].length - lines[0].replace(/^ +/, '').length : 0;
      return (Array.from(lines).map((line) => line.slice(indent))).join('\n');
    }

    // TODO: Hypothesis that this is never called.
    convertToNativeType(obj) {
      // Convert obj to current language's equivalent type if necessary
      // E.g. if language is Python, JavaScript Array is converted to a Python list
      return this.language.convertToNativeType(obj);
    }

    getStatementCount() {
      // esper = window?.esper ? self?.esper ? global?.esper ? require 'esper.js'
      let root;
      esper.plugin('lang-' + this.language.id);

      let count = 0;
      if (this.language.usesFunctionWrapping()) {
        root = this.ast.body[0].body; // We assume the 'code' is one function hanging inside the program.
      } else {
        root = this.ast.body;
      }

      traversal.walkASTCorrect(root, function(node) {
        if ((node.type == null)) { return; }
        if (node.userCode === false) { return; }
        if ([
          'ExpressionStatement', 'ReturnStatement', 'ForStatement', 'ForInStatement',
          'WhileStatement', 'DoWhileStatement', 'FunctionDeclaration', 'VariableDeclaration',
          'IfStatement', 'SwitchStatement', 'ThrowStatement', 'ContinueStatement', 'BreakStatement'
        ].includes(node.type)) {
          return ++count;
        }
      });
      // for minus `int main() { return 0;}` 3 lines for cpp
      if (this.language.id === 'cpp') {
        count -= 3;
      }
      // offset the `public class AI` and the `public static void main(String[] args) {`
      if (this.language.id === 'java') {
        count -= 2;
      }

      return count;
    }
  };
  Aether.initClass();
  return Aether;
})();

Aether.getTokenSource = function(raw) {
  if (/^\u56E7[a-zA-Z0-9+/=]+\f$/.test(raw)) {
    const { Unibabel } = require('unibabel');  // Cannot be imported in Node.js context
    const token = JSON.parse(Unibabel.base64ToUtf8(raw.substr(1, raw.length-2)));
    return token.src;
  } else {
    return raw;
  }
};

if (self != null) { self.Aether = Aether; }
if (typeof window !== 'undefined' && window !== null) { window.Aether = Aether; }
if (self != null) { if (self.esprima == null) { self.esprima = esprima; } }
if (typeof window !== 'undefined' && window !== null) { if (window.esprima == null) { window.esprima = esprima; } }

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}