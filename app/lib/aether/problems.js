// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const ranges = require('./ranges');

/*
  This must be the library instead of our modified vendored version.
  `string_score` adds method `score` to the string prototype while our vendored
  version provides a function `score` which is made global.
  We expect both globally due to some subtle dependencies.
  E.g the string prototype method `score` is used in the component misc.PropertyErrorHelper
  in the editor.
*/
const string_score = require('string_score');

// Problems #################################
//
// Error messages and hints:
//   Processed by markdown
//   In general, put correct replacement code in a markdown code span.  E.g. "Try `self.moveRight()`"
//
//
// Problem Context (problemContext)
//
// Aether accepts a problemContext parameter via the constructor options or directly to createUserCodeProblem
// This context can be used to craft better errors messages.
//
// Example:
//   Incorrect user code is 'this.attack(Brak);'
//   Correct user code is 'this.attack("Brak");'
//   Error: 'Brak is undefined'
//   If we had a list of expected string references, we could provide a better error message:
//   'Brak is undefined. Are you missing quotes? Try this.attack("Brak");'
//
// Available Context Properties:
//   stringReferences: values that should be referred to as a string instead of a variable (e.g. "Brak", not Brak)
//   thisMethods: methods available on the 'this' object
//   thisProperties: properties available on the 'this' object
//   commonThisMethods: methods that are available sometimes, but not awlays
//

// Esprima Harmony's error messages track V8's
// https://github.com/ariya/esprima/blob/harmony/esprima.js#L194

// JSHint's error and warning messages
// https://github.com/jshint/jshint/blob/master/src/messages.js

const scoreFuzziness = 0.8;
const acceptMatchThreshold = 0.5;

module.exports.createUserCodeProblem = function(options) {
  if (options == null) { options = {}; }
  if (options.aether == null) { options.aether = this; }  // Can either be called standalone or as an Aether method
  if ((options.type === 'transpile') && options.error) {
    extractTranspileErrorDetails(options);
  }
  if (options.type === 'runtime') {
    extractRuntimeErrorDetails(options);
  }

  const reporter = options.reporter || 'unknown';  // Source of the problem, like 'jshint' or 'esprima' or 'aether'
  const kind = options.kind || 'Unknown';  // Like 'W075' or 'InvalidLHSInAssignment'
  const id = reporter + '_' + kind;  // Uniquely identifies reporter + kind combination
  const config = __guard__(__guard__(options.aether != null ? options.aether.options : undefined, x1 => x1.problems), x => x[id]) || {};  // Default problem level/message/hint overrides
  const p = {isUserCodeProblem: true};
  p.id = id;
  p.level = config.level || options.level || 'error';  // 'error', 'warning', 'info'
  p.type = options.type || 'generic';  // Like 'runtime' or 'transpile', maybe later 'lint'
  p.message = config.message || options.message || `Unknown ${p.type} ${p.level}`;  // Main error message (short phrase)
  p.hint = config.hint || options.hint || '';  // Additional details about error message (sentence)
  p.range = options.range;  // Like [{ofs: 305, row: 15, col: 15}, {ofs: 312, row: 15, col: 22}], or null
  p.userInfo = options.userInfo != null ? options.userInfo : {};  // Record extra information with the error here
  p.errorCode = options.errorCode;
  p.i18nParams = options.i18nParams;
  return p;
};


// Transpile Errors

var extractTranspileErrorDetails = function(options) {
  let doubleVar, end, start;
  let range;
  const code = options.code || '';
  const codePrefix = options.codePrefix || '';
  const {
    error
  } = options;
  options.message = error.message;
  const errorContext = options.problemContext || __guard__(options.aether != null ? options.aether.options : undefined, x => x.problemContext);
  const languageID = __guard__(options.aether != null ? options.aether.options : undefined, x1 => x1.language);

  const originalLines = code.slice(codePrefix.length).split('\n');
  const lineOffset = codePrefix.split('\n').length - 1;

  // TODO: move these into language-specific plugins
  switch (options.reporter) {
    case 'jshint':
      if (options.message == null) { options.message = error.reason; }
      if (options.kind == null) { options.kind = error.code; }

      // TODO: Put this transpile error hint creation somewhere reasonable
      if (doubleVar = options.message.match(/'([\w]+)' is already defined\./)) {
        // TODO: Check that it's a var and not a function
        options.hint = `Don't use the 'var' keyword for '${doubleVar[1]}' the second time.`;
      }

      if (!options.level) {
        options.level = {E: 'error', W: 'warning', I: 'info'}[error.code[0]];
      }
      var line = error.line - codePrefix.split('\n').length;
      if (line >= 0) {
        let endCol, startCol;
        if (error.evidence != null ? error.evidence.length : undefined) {
          startCol = originalLines[line].indexOf(error.evidence);
          endCol = startCol + error.evidence.length;
        } else {
          [startCol, endCol] = Array.from([0, originalLines[line].length - 1]);
        }
        // TODO: no way this works; what am I doing with code prefixes?
        options.range = [ranges.rowColToPos(line, startCol, code, codePrefix),
                         ranges.rowColToPos(line, endCol, code, codePrefix)];
      } else {
        // TODO: if we type an unmatched {, for example, then it thinks that line -2's function wrapped() { is unmatched...
        // TODO: no way this works; what am I doing with code prefixes?
        options.range = [ranges.offsetToPos(0, code, codePrefix),
                         ranges.offsetToPos(code.length - 1, code, codePrefix)];
      }
      break;
    case 'esprima':
      // TODO: column range should extend to whole token. Mod Esprima, or extend to end of line?
      // TODO: no way this works; what am I doing with code prefixes?
      options.range = [ranges.rowColToPos(error.lineNumber - 1 - lineOffset, error.column - 1, code, codePrefix),
                       ranges.rowColToPos(error.lineNumber - 1 - lineOffset, error.column, code, codePrefix)];
      break;
    case 'acorn_loose':
      null;
      break;

    case 'csredux':
      options.range = [ranges.rowColToPos(error.lineNumber - 1 - lineOffset, error.column - 1, code, codePrefix),
                       ranges.rowColToPos(error.lineNumber - 1 - lineOffset, error.column, code, codePrefix)];
      break;
    case 'aether':
      null;
      break;

    case 'closer':
      if (error.startOffset && error.endOffset) {
        range = ranges.offsetsToRange(error.startOffset, error.endOffset, code);
        options.range = [range.start, range.end];
      }
      break;

    case 'lua2js':
      if (options.message == null) { options.message = error.message; }
      var rng = ranges.offsetsToRange(error.offset, error.offset, code, '');
      options.range = [rng.start, rng.end];
      break;

    case 'filbert':
      console.log("Incomming Error", error);
      if (error.loc) {
        const columnOffset = 0;
        // filbert lines are 1-based, columns are 0-based
        const row = error.loc.line - lineOffset - 1;
        const col = error.loc.column - columnOffset;
        start = ranges.rowColToPos(row, col, code, codePrefix);
        end = ranges.rowColToPos(row, (col + error.raisedAt) - error.pos, code, codePrefix);
        options.range = [start, end];

        switch (error.extra.kind) {
          case 'STATEMENT_EOF':
            options.message = 'Unexpected token';
            break;
          case 'CLASSIFY':
            if (error.extra.value === "'") {
              options.message = "Unterminated string constant";
            }
            break;
        }

        console.log("Extra", error.extra);
        if (error.extra) { options.extra = error.extra; }
        console.log("Outexpected Error", options);
      }
      break;

    case 'iota':
      null;
      break;

    case 'cashew':
      options.range = [ranges.offsetToPos(error.range[0], code, codePrefix),
                       ranges.offsetToPos(error.range[1], code, codePrefix)];
      options.hint = error.message;
      break;
    case 'jaba':
      if (error.location) {
        options.range = [error.location.start.offset, error.location.end.offset];
        // TODO: see if we need to do offsetToPos like with cpp
        //options.range = [ranges.offsetToPos(error.location.start.offset, code, codePrefix), ranges.offsetToPos(error.location.end.offset, code, codePrefix)]
      } else {
        console.error("Jaba error with no location information:", error);
      }
      options.hint = error.message;
      break;
      // TODO: see if we need to hide the hint like with cpp
    case 'cpp':
      if (error.location) {
        options.range = [ranges.offsetToPos(error.location.start.offset, code, codePrefix), ranges.offsetToPos(error.location.end.offset, code, codePrefix)];
      } else {
        console.error("C++ error with no location information:", error);
      }
      break;
      //options.hint = error.message
    default:
      console.warn("Unhandled UserCodeProblem reporter", options.reporter);
  }

  options.hint = options.hint || error.hint || getTranspileHint(options.message, errorContext, languageID, options.aether.raw, options.range, options.aether.options != null ? options.aether.options.simpleLoops : undefined);
  return options;
};

var getTranspileHint = function(msg, context, languageID, code, range, simpleLoops) {
  //console.log 'get transpile hint', msg, context, languageID, code, range
  // TODO: Only used by Python currently
  // TODO: JavaScript blocked by jshint range bug: https://github.com/codecombat/aether/issues/113
  let codeSnippet;
  if (simpleLoops == null) { simpleLoops = false; }
  if (["Unterminated string constant", "Unclosed string."].includes(msg) && (range != null)) {
    codeSnippet = code.substring(range[0].ofs, range[1].ofs);
    // Trim codeSnippet so we can construct the correct suggestion with an ending quote
    const firstQuoteIndex = codeSnippet.search(/['"]/);
    if (firstQuoteIndex !== -1) {
      let nonAlphNumMatch;
      const quoteCharacter = codeSnippet[firstQuoteIndex];
      codeSnippet = codeSnippet.slice(firstQuoteIndex + 1);
      if (nonAlphNumMatch = codeSnippet.match(/[^\w]/)) { codeSnippet = codeSnippet.substring(0, nonAlphNumMatch.index); }
      return `Missing a quotation mark. Try \`${quoteCharacter}${codeSnippet}${quoteCharacter}\``;
    }

  } else if (msg === "Unexpected indent") {
    if (range != null) {
      let index = range[0].ofs;
      while ((index > 0) && /\s/.test(code[index])) { index--; }
      if ((index >= 3) && /else/.test(code.substring(index - 3, index + 1))) {
        return "You are missing a ':' after 'else'. Try `else:`";
      }
    }
    return "Code needs to line up.";

  } else if ((((msg != null ? msg.indexOf("Unexpected token") : undefined) >= 0) || ((msg != null ? msg.indexOf("Unexpected identifier") : undefined) >= 0)) && (context != null)) {
    codeSnippet = code.substring(range[0].ofs, range[1].ofs);
    const lineStart = code.substring(range[0].ofs - range[0].col, range[0].ofs);
    const lineStartLow = lineStart.toLowerCase();
    // console.log "Aether transpile problem codeSnippet='#{codeSnippet}' lineStart='#{lineStart}'"

    // Check for extra thisValue + space at beginning of line
    // E.g. 'self self.moveRight()'
    const hintCreator = new HintCreator(context, languageID);
    if ((lineStart.indexOf(hintCreator.thisValue) === 0) && (lineStart.trim().length < lineStart.length)) {
      // TODO: update error range so this extra bit is highlighted
      if (codeSnippet.indexOf(hintCreator.thisValue) === 0) {
        return `Delete extra \`${hintCreator.thisValue}\``;
      } else {
        return hintCreator.getReferenceErrorHint(codeSnippet);
      }
    }

    // Check for two commands on a single line with no semi-colon
    // E.g. "self.moveRight()self.moveDown()"
    // Check for problems following a ')'
    let prevIndex = range[0].ofs - 1;
    while ((prevIndex >= 0) && /[\t ]/.test(code[prevIndex])) { prevIndex--; }
    if ((prevIndex >= 0) && (code[prevIndex] === ')')) {
      if (codeSnippet === ')') {
        return "Delete extra `)`";
      } else if (!/^\s*$/.test(codeSnippet)) {
        return "Put each command on a separate line";
      }
    }

    let parens = 0;
    for (var c of Array.from(lineStart)) { parens += (c === '(' ? 1 : c === ')' ? -1 : 0); }
    if (parens !== 0) { return "Your parentheses must match."; }

    // Check for uppercase loop
    // TODO: Should get 'loop' from problem context
    if (simpleLoops && (codeSnippet === ':') && (lineStart !== lineStartLow) && (lineStartLow === 'loop')) {
      return "Should be lowercase. Try `loop`";
    }

    // Check for malformed if statements
    if (/^\s*if /.test(lineStart)) {
      if (codeSnippet === ':') {
        return "Your if statement is missing a test clause. Try `if True:`";
      } else if (/^\s*$/.test(codeSnippet)) {
        // TODO: Upate error range to be around lineStart in this case
        return `You are missing a ':' after '${lineStart}'. Try \`${lineStart}:\``;
      }
    }

    // Catchall hint for 'Unexpected token' error
    if (/Unexpected (token|identifier)/.test(msg)) {
      return "There is a problem with your code.";
    }
  }
};

// Runtime Errors


const esperLocToAetherLoc = function(loc) {
  if ((loc == null) || (loc.start == null) || (loc.end == null)) { return undefined; }
  return [
    {row: loc.start.line-1, col: loc.start.column, ofs: loc.start.pos},
    {row: loc.end.line-1, col: loc.end.column, ofs: loc.end.pos}
  ];
};

var extractRuntimeErrorDetails = function(options) {
  let error, range;
  if (error = options.error) {
    if (options.kind == null) { options.kind = error.name; }  // I think this will pick up [Error, EvalError, RangeError, ReferenceError, SyntaxError, TypeError, URIError, DOMException]
    if (error.code) { options.errorCode = error.code; }
    if (error.i18nParams) { options.i18nParams = error.i18nParams; }
    options.message = error.message || error.toString();
    options.hint = error.hint || getRuntimeHint(options);
    if (options.level == null) { options.level = error.level; }
    if (options.userInfo == null) { options.userInfo = error.userInfo; }
    if (error.range && !options.range) {
      if (_.isNumber(error.range[0]) && _.isNumber(error.range[1]) && (error.range[0] < options.aether.raw.length)) {  // Lua doesn't have good range info for some reason
        range = ranges.offsetsToRange(error.range[0], error.range[1], options.aether.raw || '');
        options.range = [range.start, range.end];  // We expect array instead of object in options.range below
      }
    }
  }

  // NOTE: lastStatementRange set via instrumentation.logStatementStart(originalNode.originalRange)
  if (options.range == null) { options.range = options.aether != null ? options.aether.lastStatementRange : undefined; }
  if (options.aether != null) {
    const loc = __guard__(__guard__(__guard__(__guard__(options.aether != null ? options.aether.esperEngine : undefined, x3 => x3.evaluator), x2 => x2.topFrame), x1 => x1.ast), x => x.loc);
    if (options.range == null) { options.range = esperLocToAetherLoc(loc); }
  }

  if (((options.error != null ? options.error.name : undefined) != null) && !new RegExp(`^${options.error.name}`).test(options.message)) {
    options.message = `${options.error.name}: ${options.message}`;
  }

  if (options.range != null) {
    const lineNumber = options.range[0].row + 1;
    if (options.message.search(/^Line \d+/) !== -1) {
      return options.message = options.message.replace(/^Line \d+/, (match, n) => `Line ${lineNumber}`);
    } else {
      return options.message = `Line ${lineNumber}: ${options.message}`;
    }
  }
};

var getRuntimeHint = function(options) {
  const code = options.aether.raw || '';
  const context = options.problemContext || (options.aether.options != null ? options.aether.options.problemContext : undefined);
  const languageID = options.aether.options != null ? options.aether.options.language : undefined;
  const simpleLoops = options.aether.options != null ? options.aether.options.simpleLoops : undefined;

  // Check stack overflow
  if (options.message === "RangeError: Maximum call stack size exceeded") { return "Did you call a function recursively?"; }

  // Check loop ReferenceError
  if (simpleLoops && (languageID === 'python') && /ReferenceError: loop is not defined/.test(options.message)) {
    // TODO: move this language-specific stuff to language-specific code
    let hint;
    if (options.range != null) {
      let index = options.range[1].ofs;
      while ((index < code.length) && /[^\n:]/.test(code[index])) { index++; }
      if ((index >= code.length) || (code[index] === '\n')) { hint = "You are missing a ':' after 'loop'. Try `loop:`"; }
    } else {
      hint = "Are you missing a ':' after 'loop'? Try `loop:`";
    }
    return hint;
  }

  // Use problemContext to add hints
  if (context == null) { return; }
  const hintCreator = new HintCreator(context, languageID);
  return hintCreator.getHint(code, options);
};

class HintCreator {
  // Create hints for an error message based on a problem context
  // TODO: better class name, move this to a separate file

  constructor(context, languageID) {
    // TODO: move this language-specific stuff to language-specific code
    this.thisValue = (() => { switch (languageID) {
      case 'python': return 'self';
      case 'cofeescript': return '@';
      default: return 'this';
    } })();

    this.realThisValueAccess = (() => { switch (languageID) {
      case 'python': return 'self.';
      case 'cofeescript': return '@';
      default: return 'this.';
    } })();

    // We use `hero` as `this` in CodeCombat now, so all `this` related hints
    // we get in the problem context should really refrence `hero`
    this.thisValueAccess = (() => { switch (languageID) {
      case 'python': return 'hero.';
      case 'cofeescript': return 'hero.';
      case 'lua': return 'hero:';
      default: return 'hero.';
    } })();

    this.newVariableTemplate = (() => { switch (languageID) {
      case 'javascript': return _.template('var <%= name %> = ');
      default: return _.template('<%= name %> = ');
    } })();

    this.methodRegex = (() => { switch (languageID) {
      case 'python': return new RegExp("self\\.(\\w+)\\s*\\(");
      case 'cofeescript': return new RegExp("@(\\w+)\\s*\\(");
      default: return new RegExp("this\\.(\\w+)\\(");
    } })();

    this.context = context != null ? context : {};
  }

  getHint(code, {message, range, error, aether}) {
    let hint, missingMethodMatch, missingProperty, missingReference, target;
    console.log(error);
    if (this.context == null) { return; }
    if ((error.code === 'UndefinedVariable') && (error.when === 'write') && (aether.language.id === 'javascript')) {
      return `Missing \`var\`. Use \`var ${error.ident} =\` to make a new variable.`;
    }

    if (error.code === "CallNonFunction") {
      const ast = error.targetAst;
      if ((ast.type === "MemberExpression") && !ast.computed) {
        const extra = "";
        target = ast.property.name;
        if (error.candidates != null) {
          let newName;
          const candidatesLow = (Array.from(error.candidates).map((s) => s.toLowerCase()));
          const idx = candidatesLow.indexOf(target.toLowerCase());
          if (idx !== -1) {
            newName = error.targetName.replace(target, error.candidates[idx]);
            return `Look out for capitalization: \`${error.targetName}\` should be \`${newName}\`.`;
          }
          const sm = this.getScoreMatch(target, [{candidates: error.candidates, msgFormatFn(match) { return match; }}]);
          if (sm != null) {
            newName = error.targetName.replace(target, sm);
            return `Look out for spelling issues: did you mean \`${newName}\` instead of \`${error.targetName}\`?`;
          }
        }

        return `\`${ast.object.srcName}\` has no method \`${ast.property.name}\`.`;
      }
    }

    if ((missingMethodMatch = message.match(/has no method '(.*?)'/)) || message.match(/is not a function/) || message.match(/has no method/)) {
      // NOTE: We only get this for valid thisValue and parens: self.blahblah()
      // NOTE: We get different error messages for this based on javascript engine:
      // Chrome: 'undefined is not a function'
      // Firefox: 'tmp5[tmp6] is not a function'
      // test framework: 'Line 1: Object #<Object> has no method 'moveright'
      if (missingMethodMatch) {
        target = missingMethodMatch[1];
      } else if (range != null) {
        // TODO: this is not covered by any test cases yet, because our test environment throws different errors
        const codeSnippet = code.substring(range[0].ofs, range[1].ofs);
        missingMethodMatch = this.methodRegex.exec(codeSnippet);
        if (missingMethodMatch != null) { target = missingMethodMatch[1]; }
      }
      hint = (target != null) ? this.getNoFunctionHint(target) : undefined;
    } else if (missingReference = message.match(/([^\s]+) is not defined/)) {
      hint = this.getReferenceErrorHint(missingReference[1]);
    } else if (missingProperty = message.match(/Cannot (?:read|call) (?:property|method) '([\w]+)' of (?:undefined|null)/)) {
      // Chrome: "Cannot read property 'moveUp' of undefined"
      // TODO: Firefox: "tmp5 is undefined"
      hint = this.getReferenceErrorHint(missingProperty[1]);

      // Chrome: "Cannot read property 'pos' of null"
      // TODO: Firefox: "tmp10 is null"
      // TODO: range is pretty busted, but row seems ok so we'll use that.
      // TODO: Should we use a different message if object was 'undefined' instead of 'null'?
      if ((hint == null) && (range != null)) {
        let nullObjMatch;
        const line = code.substring(range[0].ofs - range[0].col, code.indexOf('\n', range[1].ofs));
        const nullObjRegex = new RegExp(`(\\w+)\\.${missingProperty[1]}`);
        if (nullObjMatch = nullObjRegex.exec(line)) {
          hint = `'${nullObjMatch[1]}' was null. Use a null check before accessing properties. Try \`if ${nullObjMatch[1]}:\``;
        }
      }
    }
    return hint;
  }

  getNoFunctionHint(target) {
    // Check thisMethods
    let hint = this.getNoCaseMatch(target, this.context.thisMethods, match => {
      // TODO: Remove these format tests someday.
      // "Uppercase or lowercase problem. Try #{@thisValueAccess}#{match}()"
      // "Uppercase or lowercase problem.  \n  \n\tTry: #{@thisValueAccess}#{match}()  \n\tHad: #{codeSnippet}"
      // "Uppercase or lowercase problem.  \n  \nTry:  \n`#{@thisValueAccess}#{match}()`  \n  \nInstead of:  \n`#{codeSnippet}`"
      return `Uppercase or lowercase problem. Try \`${this.thisValueAccess}${match}()\``;
    });
    if (hint == null) { hint = this.getScoreMatch(target, [{candidates: this.context.thisMethods, msgFormatFn: match => {
      return `Try \`${this.thisValueAccess}${match}()\``;
    }
  }]); }
    // Check commonThisMethods
    if (hint == null) { hint = this.getExactMatch(target, this.context.commonThisMethods, match => `You do not have an item equipped with the ${match} skill.`); }
    if (hint == null) { hint = this.getNoCaseMatch(target, this.context.commonThisMethods, match => `Did you mean ${match}? You do not have an item equipped with that skill.`); }
    if (hint == null) { hint = this.getScoreMatch(target, [{candidates: this.context.commonThisMethods, msgFormatFn(match) {
      return `Did you mean ${match}? You do not have an item equipped with that skill.`;
    }
  }]); }
    if (hint == null) { hint = `You don't have a \`${target}\` method.`; }
    return hint;
  }

  getReferenceErrorHint(target) {
    // Check missing quotes
    let hint = this.getExactMatch(target, this.context.stringReferences, match => `Missing quotes. Try \`\"${match}\"\``);
    // Check this props
    if (hint == null) { hint = this.getExactMatch(target, this.context.thisMethods, match => {
      return `Try \`${this.thisValueAccess}${match}()\``;
    }); }
    if (hint == null) { hint = this.getExactMatch(target, this.context.thisProperties, match => {
      return `Try \`${this.thisValueAccess}${match}\``;
    }); }
    // Check case-insensitive, quotes, this props
    if ((hint == null) && (target.toLowerCase() === this.thisValue.toLowerCase())) {
      hint = `Uppercase or lowercase problem. Try \`${this.thisValue}\``;
    }
    if (hint == null) { hint = this.getNoCaseMatch(target, this.context.stringReferences, match => `Missing quotes.  Try \`\"${match}\"\``); }
    if (hint == null) { hint = this.getNoCaseMatch(target, this.context.thisMethods, match => {
      return `Try \`${this.thisValueAccess}${match}()\``;
    }); }
    if (hint == null) { hint = this.getNoCaseMatch(target, this.context.thisProperties, match => {
      return `Try \`${this.thisValueAccess}${match}\``;
    }); }
    // Check score match, quotes, this props
    if (hint == null) { hint = this.getScoreMatch(target, [
      {candidates: [this.thisValue], msgFormatFn(match) { return `Try \`${match}\``; }},
      {candidates: this.context.stringReferences, msgFormatFn(match) { return `Missing quotes. Try \`\"${match}\"\``; }},
      {candidates: this.context.thisMethods, msgFormatFn: match => `Try \`${this.thisValueAccess}${match}()\``},
      {candidates: this.context.thisProperties, msgFormatFn: match => `Try \`${this.thisValueAccess}${match}\``}]); }
    // Check commonThisMethods
    if (hint == null) { hint = this.getExactMatch(target, this.context.commonThisMethods, match => `You do not have an item equipped with the ${match} skill.`); }
    if (hint == null) { hint = this.getNoCaseMatch(target, this.context.commonThisMethods, match => `Did you mean ${match}? You do not have an item equipped with that skill.`); }
    if (hint == null) { hint = this.getScoreMatch(target, [{candidates: this.context.commonThisMethods, msgFormatFn(match) {
      return `Did you mean ${match}? You do not have an item equipped with that skill.`;
    }
  }]); }
    // Check enemy defined
    if (!hint && (target.toLowerCase().indexOf('enemy') > -1) && _.contains(this.context.thisMethods, 'findNearestEnemy')) {
      hint = `There is no \`${target}\`. Use \`${this.newVariableTemplate({name:target})}${this.thisValueAccess}findNearestEnemy()\` first.`;
    }

    // Try score match with this value prefixed
    // E.g. target = 'selfmoveright', try 'self.moveRight()''
    if ((hint == null) && ((this.context != null ? this.context.thisMethods : undefined) != null)) {
      const thisPrefixed = (Array.from(this.context.thisMethods).map((method) => this.thisValueAccess + method));
      hint = this.getScoreMatch(target, [{candidates: thisPrefixed, msgFormatFn(match) {
        return `Try \`${match}()\``;
      }
    }]);
    }

    return hint;
  }

  getExactMatch(target, candidates, msgFormatFn) {
    if (candidates == null) { return; }
    if (Array.from(candidates).includes(target)) { return msgFormatFn(target); }
  }

  getNoCaseMatch(target, candidates, msgFormatFn) {
    let index;
    if (candidates == null) { return; }
    const candidatesLow = (Array.from(candidates).map((s) => s.toLowerCase()));
    if ((index = candidatesLow.indexOf(target.toLowerCase())) >= 0) { return msgFormatFn(candidates[index]); }
  }

  getScoreMatch(target, candidatesList) {
    // candidatesList is an array of candidates objects. E.g. [{candidates: [], msgFormatFn: ()->}, ...]
    // This allows a score match across multiple lists of candidates (e.g. thisMethods and thisProperties)
    if (string_score == null) { return; }
    let [closestMatch, closestScore, msg] = Array.from(['', 0, '']);
    for (var set of Array.from(candidatesList)) {
      if (set.candidates != null) {
        for (var match of Array.from(set.candidates)) {
          var matchScore = match.score(target, scoreFuzziness);
          if (matchScore > closestScore) { [closestMatch, closestScore, msg] = Array.from([match, matchScore, set.msgFormatFn(match)]); }
        }
      }
    }
    if (closestScore >= acceptMatchThreshold) { return msg; }
  }
}

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}