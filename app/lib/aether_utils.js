// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS202: Simplify dynamic range loops
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
import './aether/aether.coffee';

Aether.addGlobal('Vector', require('./world/vector'));
Aether.addGlobal('_', _);

export const createAetherOptions = function(options) {
  if (!options.functionName) { throw new Error('Specify a function name to create an Aether instance'); }
  if (!options.codeLanguage) { throw new Error('Specify a code language to create an Aether instance'); }

  const aetherOptions = {
    functionName: options.functionName,
    protectAPI: !options.skipProtectAPI,
    includeFlow: Boolean(options.includeFlow),
    noVariablesInFlow: true,
    skipDuplicateUserInfoInFlow: true,  // Optimization that won't work if we are stepping with frames
    yieldConditionally: options.functionName === 'plan',
    simpleLoops: true,
    whileTrueAutoYield: true,
    globals: ['Vector', '_'],
    problems: {
      jshint_W040: {level: 'ignore'},
      jshint_W030: {level: 'ignore'},  // aether_NoEffect instead
      jshint_W038: {level: 'ignore'},  // eliminates hoisting problems
      jshint_W091: {level: 'ignore'},  // eliminates more hoisting problems
      jshint_E043: {level: 'ignore'},  // https://github.com/codecombat/codecombat/issues/813 -- since we can't actually tell JSHint to really ignore things
      jshint_Unknown: {level: 'ignore'},  // E043 also triggers Unknown, so ignore that, too
      aether_MissingThis: {level: 'error'}
    },
    problemContext: options.problemContext,
    //functionParameters: # TODOOOOO
    executionLimit: 3 * 1000 * 1000,
    language: options.codeLanguage,
    useInterpreter: true
  };
  let parameters = functionParameters[options.functionName];
  if (!parameters) {
    console.warn(`Unknown method ${options.functionName}: please add function parameters to lib/aether_utils.coffee.`);
    parameters = [];
  }
  if (options.functionParameters && !_.isEqual(options.functionParameters, parameters)) {
    console.error(`Update lib/aether_utils.coffee with the right function parameters for ${options.functionName} (had: ${parameters} but this gave ${options.functionParameters}.`);
    parameters = options.functionParameters;
  }
  aetherOptions.functionParameters = parameters.slice();
  //console.log 'creating aether with options', aetherOptions
  return aetherOptions;
};

// TODO: figure out some way of saving this info dynamically so that we don't have to hard-code it: #1329
var functionParameters = {
  hear: ['speaker', 'message', 'data'],
  makeBid: ['tileGroupLetter'],
  findCentroids: ['centroids'],
  isFriend: ['name'],
  evaluateBoard: ['board', 'player'],
  getPossibleMoves: ['board'],
  minimax_alphaBeta: ['board', 'player', 'depth', 'alpha', 'beta'],
  distanceTo: ['target'],

  chooseAction: [],
  plan: [],
  initializeCentroids: [],
  update: [],
  getNearestEnemy: [],
  die: []
};

export const generateSpellsObject = function(options) {
  let left;
  const {level, levelSession, token} = options;
  const {createAetherOptions} = require('lib/aether_utils');
  const aetherOptions = createAetherOptions({functionName: 'plan', codeLanguage: levelSession.get('codeLanguage'), skipProtectAPI: (options.level != null ? options.level.isType('game-dev') : undefined)});
  const spellThang = {thang: {id: 'Hero Placeholder'}, aether: new Aether(aetherOptions)};
  const spells = {"hero-placeholder/plan": {thang: spellThang, name: 'plan'}};
  const source = (left = token || __guard__(__guard__(levelSession.get('code'), x1 => x1['hero-placeholder']), x => x.plan)) != null ? left : '';
  try {
    spellThang.aether.transpile(source);
  } catch (e) {
    console.log(`Couldn't transpile!\n${source}\n`, e);
    spellThang.aether.transpile('');
  }
  return spells;
};

export const replaceSimpleLoops = function(source, language) {
  switch (language) {
    case 'python': return source.replace(/loop:/, 'while True:');
    case 'javascript': case 'java': case 'cpp': return source.replace(/loop {/, 'while (true) {');
    case 'lua': return source.replace(/loop\n/, 'while true do\n');
    case 'coffeescript': return source;
    default: return source;
  }
};

export const translateJS = function(jsCode, language, fullCode) {
  if (language == null) { language = 'cpp'; }
  if (fullCode == null) { fullCode = true; }
  if (['cpp', 'java'].includes(language)) { return translateJSBrackets(jsCode, language, fullCode); }
  if (['python', 'lua', 'coffeescript'].includes(language)) { return translateJSWhitespace(jsCode, language); }
  if (language === 'javascript') { return jsCode; }
  console.warn('Unsupported language translation: from javascript to', language);
  return jsCode;
};

var translateJSBrackets = function(jsCode, language, fullCode) {
  // Supports cpp or java

  // Find all global statement(except global variables) and move into main function
  let lines;
  if (language == null) { language = 'cpp'; }
  if (fullCode == null) { fullCode = true; }
  const reorderGlobals = function(strs) {
    let i;
    let insertPlace = strs.length-1;
    for (i = strs.length-2; i >= 0; i--) {
      if (/\n?function/.test(strs[i])) { continue; }
      if (/^[ \t]+\/\//.test(strs[i])) { continue; }
      insertPlace -= 1;
      strs.splice(insertPlace, 0, strs.splice(i,1)[0]);
    }

    const mainLen = strs[strs.length-1].split('\n').length;
    const final = strs.splice(insertPlace).join('');
    const finals = final.split('\n');
    insertPlace = finals.length - mainLen;
    for (i = finals.length-mainLen-1; i >= 0; i--) {
      if (!finals[i]) { continue; }
      if (/var /.test(finals[i])) { continue; }
      insertPlace -= 1;
      finals.splice(insertPlace, 0, finals.splice(i,1)[0]);
    }

    return strs.concat([finals.slice(0, insertPlace).join('\n'), finals.slice(insertPlace).join('\n')]);
  };

  // Find header comments function definitions in order to hoist them out of the main function
  const matchBrackets = function(str, startIndex) {
    let cc = 0;
    for (let i = startIndex, end = str.length, asc = startIndex <= end; asc ? i < end : i > end; asc ? i++ : i--) {
      if (str[i] === '{') { cc += 1; }
      if (str[i] === '}') {
        cc -= 1;
        if (!cc) { return i+2; }
      }
    }
  };
  const splitFunctions = function(str) {
    let startComments;
    let result;
    const creg = /\n?[ \t]*[^\/]/;
    const startCommentReg = /^\n?(\/\/.*?\n)*\n/;
    const comments = startCommentReg.exec(str);
    if (comments) {
      startComments = comments[0].slice(0, -1); // left the tailing \n
      str = str.slice(startComments.length);
      if (!creg.exec(str)) {
        return [startComments, str];
      }
    } else {
      const strComments = '';
    }

    const indices = [];
    const reg = /\n(\/\/.*?\n)*function/gi;
    if (str.startsWith("function ")) { indices.push(0); }
    while (result = reg.exec(str)) {
      indices.push(result.index+1);
    }
    const split = [];
    let end = 0;
    // split.push {s: 0, e: indices[0]} if indices.length
    for (var i of Array.from(indices)) {
      if (end !== i) { split.push({s: end, e: i}); }
      end = matchBrackets(str, i);
      split.push({s: i, e: end});
    }
    split.push({s: end, e: str.length});
    const header = startComments ? [startComments] : [];
    return header.concat(reorderGlobals(split.map(s => str.slice(s.s, s.e)) ));
  };

  let jsCodes = splitFunctions(jsCode);
  if (fullCode) {
    // Remove whitespace-only pieces, except for in the last piece
    jsCodes = _.filter(jsCodes.slice(0, jsCodes.length - 1), piece => piece.replace(/\s/g, '').length).concat(jsCodes[jsCodes.length - 1]);
  } else {
    // Remove all whitespace-only pieces
    jsCodes = _.filter(jsCodes, piece => piece.replace(/\s/g, '').length);
  }
  let len = jsCodes.length;
  if (len) {
    lines = jsCodes[len-1].trimStart().split('\n');
  } else {
    lines = [];
  }
  //console.log "Split code segments into", _.cloneDeep(jsCodes)
  if (fullCode) {
    if (language === 'cpp') {
      jsCodes[len-1] = `\
int main() {
${(lines.map(line => '    ' + line)).join('\n')}
    return 0;
}\
`;
    } else if (language === 'java') {
      if ((len > 2) && !(/function/.test(jsCodes[len-2]))) {
        jsCodes[len-2] = (jsCodes[len-2].split('\n').map(function(line) {
          if (/ = /.test(line)) {
            line = 'static ' + line;
          }
          return line;
        })).join('\n');
      }

      const hasHeader = /^\/\//.test(jsCodes[0]);
      const startIndex = hasHeader ? 1 : 0;
      const functionLines = jsCodes.splice(startIndex, len - 1 - startIndex).join('\n').trimStart().split('\n');
      while (functionLines.length && !functionLines[0]) { functionLines.shift(); }  // Trim starting whitespace lines
      len = jsCodes.length;
      jsCodes[len-1] = `\
public class AI {${functionLines.length ? '\n' + (functionLines.map(line => '    ' + line)).join('\n') : ''}
    public static void main(String[] args) {
${(lines.map(line => '        ' + line)).join('\n')}
    }
}\
`;
    }
  } else if (len) {
    jsCodes[len-1] = (lines.map(line => ' ' + line)).join('\n');  // Add whitespace at beginning of each line to make regexes easier
  }

  const functionReturnType = language === 'cpp' ? 'auto' : 'public static var';  // TODO: figure out some auto return types for Java
  const functionParamType = language === 'cpp' ? 'auto' : 'Object';  // TODO: figure out some auto/void param types for Java
  for (let i = 0, end = len, asc = 0 <= end; asc ? i < end : i > end; asc ? i++ : i--) {
    var s = jsCodes[i];
    s = s.replace(/function (.+?)\((.*?)\)/g, function(match, functionName, functionParams) {
      const typedParameters = _.filter(functionParams.split(/, ?/)).map(e => `${functionParamType} ${e}`).join(', ');
      return `${functionReturnType} ${functionName}(${typedParameters})`;
    });
    s = s.replace(/var (x|y|z|dist)/g, 'float $1');
    s = s.replace(/var (\w+)Index/g, 'int $1Index');
    s = s.replace(/var (i|j|k)(?![a-zA-Z0-9_])/g, 'int $1');
    s = s.replace(/\ ===\ /g, ' == ');
    s = s.replace(/\ !== /g, ' != ');
    s = s.replace(/hero\.throw\(/g, 'hero.throwEnemy(');
    s = s.replace(/\ = \[([^;]*)\];/g, ' = {$1};');

    if (language === 'cpp') {
      s = s.replace(/\.length/g, '.size()');
      s = s.replace(/\.push\(/g, '.push_back(');
      s = s.replace(/\.pop\(/g, '.pop_back(');
      s = s.replace(/\.shift\(/g, '.pop(');
      s = s.replace(/\ var /g, ' auto ');
      s = s.replace(/\(var /g, '(auto ');
      s = s.replace(/\nvar /g, '\nauto ');
      s = s.replace(/\ const /g, ' const auto ');
      s = s.replace(/\nconst /g, '\nconst auto ');
      s = s.replace(/\ return \[([^;]*)\];/g, ' return {$1};');
    }

    // TODO: figure out how we are going to call other methods in Java
    // TODO: figure out how we are going to handle {x: 34, y: 30} object literals in Java
    // TODO: figure out how we are going to handle array methods in Java

    // Don't substitute these within comments
    var noComment = '^( *[^/\\r\\n]*?)'; // keep leading whitespace
    if (language === 'cpp') {
      var newRegex = new RegExp(noComment + '([^*])new ', 'gm');
      while (newRegex.test(s)) {
        s = s.replace(newRegex, '$1$2*new ');
      }
    }
    var quotesReg = new RegExp(noComment + "'(.*?)'", 'gm');
    while (quotesReg.test(s)) {
      s = s.replace(quotesReg, '$1"$2"');
    }
    // first replace ' to " then replace object
    if (language === 'cpp') {
      s = s.replace(/\{\s*"?x"?\s*:\s*([^,]+),\s*"?y"?\s*:\s*([^\}]*)\}/g, '{$1, $2}');  // {x:1, y:1} -> {1, 1}
    } else if (language === 'java') {
      // Let's use Vectors instead of object literals in this case
      s = s.replace(/\{\s*"?x"?\s*:\s*([^,]+),\s*"?y"?\s*:\s*([^\}]*)\}/g, 'new Vector($1, $2)');  // {x:1, y:1} -> new Vector(1, 1)
    }
    jsCodes[i] = s;
  }

  if (!fullCode) {
    if (len) {
      lines = jsCodes[len-1].split('\n');
      jsCodes[len-1] = (lines.map(line => line.slice(1))).join('\n');  // Remove leading convenience whitespace that we added
    } else {
      jsCodes = [];
    }
  }

  return jsCodes.join('\n');
};

var translateJSWhitespace = function(jsCode, language) {
  // Supports python, lua, or coffeescript

  if (language == null) { language = 'lua'; }
  let s = jsCode.split('\n').map(line => ' ' + line).join('\n');  // Add whitespace at beginning of each line to make regexes easier

  if (language === 'lua') {
    s = s.replace(/function (.+?)\((.*)\) ?{/g, 'function $1($2)');  // Just remove the trailing {
  } else if (language === 'python') {
    s = s.replace(/function (.+?)\((.*)\) ?{/g, 'def $1($2):');  // Convert trailing { to :
  } else if (language === 'coffeescript') {
    s = s.replace(/function (.+?)\((.*)\) ?{/g, function(match, functionName, functionParams) {
      if (functionParams) {
        return `${functionName} = (${functionParams}) ->`;
      } else {
        return `${functionName} = ->`;
      }
    });
  }

  // Rewrite for-loops
  // for(i=0; i < archers.length; i++) {
  //     var archer = archers[i];
  const cStyleForInLoopWithVariableAssignmentRegex = /for ?\((?:var )?(.+?) ?= ?0; ?\1 ?< ?(.+?).length; ?(?:.*?\+\+.*?)\) *\{?\n(.*)var (.+?) ?= ?\2\[\1\];? *$/gm;
  if (language === 'lua') {
    // for i, archer in pairs(archers) do
    s = s.replace(cStyleForInLoopWithVariableAssignmentRegex, 'for $1, $4 in pairs($2) do');
  } else if (language === 'python') {
    //s = s.replace cStyleForInLoopWithVariableAssignmentRegex, 'for $1, $4 in enumerate($2):'  # I guess we usually do the other way for scaffolding learning similar to how we do it in JS instead of teaching enumerate
    s = s.replace(cStyleForInLoopWithVariableAssignmentRegex, 'for $1 in range(len($2)):\n$3$4 = $2[$1]');
  } else if (language === 'coffeescript') {
    // for archer in archers
    s = s.replace(cStyleForInLoopWithVariableAssignmentRegex, 'for $4, $1 in $2');
  }

  // for(i=0; i < archers.length; i++) {
  const cStyleForInLoopRegex = /for ?\((?:var )?(.+?) ?= ?0; ?\1 ?< ?(.+?).length; ?(?:.*?\+\+.*?)\) *\{?/g;
  if (language === 'lua') {
    // for i in pairs(archers) do
    s = s.replace(cStyleForInLoopRegex, 'for $1 in pairs($2) do');
  } else if (language === 'python') {
    // for i in range(0, len(archers)):
    s = s.replace(cStyleForInLoopRegex, 'for $1 in range(len($2)):');
  } else if (language === 'coffeescript') {
    // for i in [0...archers.length]
    s = s.replace(cStyleForInLoopRegex, 'for $1 in [0...$2.length]');
  }

  // for(i=0; i < 10; i++) {
  const cStyleForLoopRegex = /for ?\((?:var )?(.+?) ?= ?(\d+); ?\1 ?< ?(.+?); ?(?:.*?\+\+.*?)\) *\{?/g;
  if (language === 'lua') {
    // for i=0, 10 do
    s = s.replace(cStyleForLoopRegex, 'for $1=$2, $3 do');
  } else if (language === 'python') {
    // for i in range(0, 10):
    s = s.replace(cStyleForLoopRegex, 'for $1 in range($2, $3):');
  } else if (language === 'coffeescript') {
    // for i in [0...10]
    s = s.replace(cStyleForLoopRegex, 'for $1 [$2...$3]');
  }

  // for(y=110; y >= 38; i -= 18) {
  // This is brittle and will not get inclusive vs. exclusive ranges right, but better than nothing
  const cStyleForLoopWithArithmeticRegex = /for ?\((?:var )?(.+?) ?= ?(\d+); ?\1 ?(<=|<|>=|>) ?(.+?); ?\1 ?\+?(-?)= ?(.*)\) *\{?/g;
  if (language === 'lua') {
    // for y=110, 38, -18 do
    s = s.replace(cStyleForLoopWithArithmeticRegex, 'for $1=$2, $4, $5$6 do');
  } else if (language === 'python') {
    // for y in range(110, 38, -18):
    s = s.replace(cStyleForLoopWithArithmeticRegex, 'for $1 in range($2, $4, $5$6):');
  } else if (language === 'coffeescript') {
    // for y in [110...38, -18]
    s = s.replace(cStyleForLoopWithArithmeticRegex, 'for $1 [$2...$4, $5$6]');
  }

  // There are a lot of other for-loop possibilities, but we'll handle those with manual solutions

  if (language === 'lua') {
    s = s.replace(/\ ===\ /g, ' == ');
    s = s.replace(/\ !==? /g, ' ~= ');
    s = s.replace(/(\S+)(\+|-){2}/g, '$1 = $1 $2 1');  // Rewrite postfix ++ and --, like count++ -> count = count + 1
    s = s.replace(/(\+|-){2}(\S+)/g, '$2 = $2 $1 1');  // Rewrite prefix  ++ and --, like ++count -> count = count + 1
    s = s.replace(/(\S+) ?(\+|-|\*|\/)= ?(.+)/g, '$1 = $1 $2 $3');  // Rewrite +=, -=, etc.
  } else if (language === 'coffeescript') {
    s = s.replace(/\ ===?\ /g, ' is ');
    s = s.replace(/\ !==? /g, ' isnt ');
  } else if (language === 'python') {
    s = s.replace(/\ ===?\ /g, ' == ');  // Maybe we should rewrite to `is` instead?
    s = s.replace(/\ !==? /g, ' != ');
    s = s.replace(/(\S+)(\+|-){2}/g, '$1 $2= 1');  // Rewrite postfix ++ and --, like count++ -> count += 1
    s = s.replace(/(\+|-){2}(\S+)/g, '$2 $1= 1');  // Rewrite prefix  ++ and --, like ++count -> count += 1
  }

  s = s.replace(/\ &&\ /g, ' and ');
  s = s.replace(/\ \|\|\ /g, ' or ');
  s = s.replace(/\!([$A-Z_(])/gi, 'not $1');

  if (language === 'python') {
    s = s.replace(/\.push\(/g, '.append(');
    s = s.replace(/\.shift\(0?\)/g, '.pop(0)');
  } else if (language === 'lua') {
    s = s.replace(/\.push\(/g, '.insert(');
    s = s.replace(/\.pop\(/g, '.remove(');
    s = s.replace(/\.shift\(0?\)/g, '.remove(0)');
  }

  if (language === 'lua') {
    s = s.replace(/\ var /g, ' local ');
    s = s.replace(/\ = \[([^;]*)\];/g, ' = {$1};');
    s = s.replace(/\(var /g, '(local ');
    s = s.replace(/\nvar /g, '\nlocal ');
    s = s.replace(/\ return \[([^;]*)\];/g, ' return {$1};');
  } else if (['python', 'coffeescript'].includes(language)) {
    s = s.replace(/^ *var [^=\n]*$\n/gm, '');  // Remove variable declarations without initialization
    s = s.replace(/\ var /g, ' ');
    s = s.replace(/\(var /g, '(');
    s = s.replace(/\nvar /g, '\n');
  }

  // Don't substitute these within comments
  const noComment = '^ *([^/\\r\\n]*?)';
  if (['python', 'lua'].includes(language)) {
    const newRegex = new RegExp(noComment + 'new ', 'gm');
    while (newRegex.test(s)) {
      s = s.replace(newRegex, '$1');
    }
  }

  // Rewrite comments
  const commentStart = commentStarts[language] || '#';
  const commentStartRegex = new RegExp("([ \t]*?)//", 'gm');
  s = s.replace(commentStartRegex, `$1${commentStart}`);  // `    // Comment` -> `    # Comment`

  // No semicolons
  s = s.replace(/;/g, '');

  // For Lua, replace periods with colons for method calls (but not other property accesses)
  if (language === 'lua') {
    s = s.replace(/([$A-Z_][$0-9a-z_]*)\.([$A-Za-z_][0-9A-Za-z_$]*)\(/gi, '$1:$2(');
    // We still use periods for Math (still using the JavaScript library), it's static vs. instance method thing
    // Hack: re-replace back to dots in those cases by looking at initial capital letter of variable name
    s = s.replace(/([$A-Z_][$0-9a-z_]*):([$A-Za-z_][0-9A-Za-z_$]*)\(/g, '$1.$2(');
  }

  // Rewrite while loops
  if (language === 'lua') {
    s = s.replace(/^(\s*while) ?\((.*)\) ?\{?/gm, '$1 $2 do');
  } else if (language === 'python') {
    s = s.replace(/^(\s*while) ?\((.*)\) ?\{?/gm, '$1 $2:');
  } else if (language === 'coffeescript') {
    s = s.replace(/^(\s*while) ?\((.*)\) ?\{?/gm, '$1 $2');
  }

  // Rewrite if conditions
  if (language === 'lua') {
    s = s.replace(/else if/g, 'elseif');
    s = s.replace(/(} *)?( *(if|elseif)) ?\((.*)\) ?\{?/gm, '$2 $4 then');
  } else if (language === 'python') {
    s = s.replace(/else if/g, 'elif');
    s = s.replace(/(} *)?( *(if|elif)) ?\((.*)\) ?\{?/gm, '$2 $4:');
    s = s.replace(/(}\s*)?else\s*{/g, 'else:');
  } else if (language === 'coffeescript') {
    s = s.replace(/(} *)?( *(if|else if)) ?\((.*)\) ?\{?/gm, '$2 $4');
    s = s.replace(/(}\s*)?else\s*{/g, 'else');
  }

  // Rewrite else { to else
  s = s.replace(/(}\s*)?else\s*{/g, 'else');

  if (language === 'lua') {
    // Rewrite standalone `}` to `end`
    s = s.replace(/^(\s*)\} *$/gm, '$1end');
    // Remove `end` as part of part of if/elseif/else chains
    s = s.replace(/^(\s*)end ?}?\n((\n|\s|--.*\n)*^\1)(elseif|else)/gm, '$2$4');  // The ^\1 only matches the same level of indentation
  } else if (['python', 'coffeescript'].includes(language)) {
    // Remove stanadlone `}`
    s = s.replace(/\n\s*\} *$/gm, '');
  }

  if (language === 'lua') {
    s = s.replace(/null/g, 'nil');
    s = s.replace(/(\S+)\.length/g, '#$1');  // Do this after if/else paren/bracket replacement
  } else if (language === 'python') {
    s = s.replace(/true/g, 'True');
    s = s.replace(/false/g, 'False');
    s = s.replace(/null/g, 'None');
    s = s.replace(/(\S+)\.length/g, 'len($1)');  // Do this after if/else paren/bracket replacement
  }

  if (language === 'coffeescript') {
    // Remove unnecessary parenthesis in CofeeScript
    s = s.replace(/([$A-Z_][0-9A-Z_$]*)\(([^()]+)\)(?!\))$/gim, '$1 $2');
    // Use simple loops in CoffeeScript
    s = s.replace(/while true$/gm, 'loop');
  }

  if (language === 'lua') {
    // Convert : to =. {x:1, y:1} -> {x=1, y=1}
    s = s.replace(/\{\s*['"]?(\S+?)['"]?\s*:\s*([^,]+)\}/g, '{$1=$2}');  // 1 element
    s = s.replace(/\{\s*['"]?(\S+?)['"]?\s*:\s*([^,]+),\s*['"]?(\S+?)['"]?\s*:\s*([^\}]*)\}/g, '{$1=$2, $3=$4}');  // 2 elements
    s = s.replace(/\{\s*['"]?(\S+?)['"]?\s*:\s*([^,]+),\s*['"]?(\S+?)['"]?\s*:\s*([^\}]*),\s*['"]?(\S+?)['"]?\s*:\s*([^\}]*)\}/g, '{$1=$2, $3=$4, $4=6}');  // 3 elements
    // TODO: something flexible for arbitrary n elements
  } else if (language === 'python') {
    // Add quotes. {x:1, y:1} -> {"x": 1, "y": 1}
    s = s.replace(/\{\s*['"]?(\S+?)['"]?\s*:\s*([^,]+)\}/g, '{"$1": $2}');  // 1 element
    s = s.replace(/\{\s*['"]?(\S+?)['"]?\s*:\s*([^,]+),\s*['"]?(\S+?)['"]?\s*:\s*([^\}]*)\}/g, '{"$1": $2, "$3": $4}');  // 2 elements
    s = s.replace(/\{\s*['"]?(\S+?)['"]?\s*:\s*([^,]+),\s*['"]?(\S+?)['"]?\s*:\s*([^\}]*),\s*['"]?(\S+?)['"]?\s*:\s*([^\}]*)\}/g, '{"$1": $2, "$3": $4, "$5": $6}');  // 3 elements
  }
    // TODO: something flexible for arbitrary n elements

  if (language === 'lua') {
    // Try incrementing all literal array indexes under, say, 10 by 1 to offset 1-based indexing. Hack, but most of those levels will need manual attention anyway.
    s = s.replace(/\[(\d)\]/g, (match, index) => `[${parseInt(index, 10) + 1}]`);
  }

  // TODO: see if we can do something about lack of a continue statement in Lua? Maybe too hard and we should give up.

  const lines = s.split('\n');
  const output = (lines.map(line => line.slice(1))).join('\n');  // Remove leading convenience whitespace that we added
  return output;
};

const startsWithVowel = s => Array.from('aeiouAEIOU').includes(s[0]);

export const filterMarkdownCodeLanguages = function(text, language) {
  if (!text) { return ''; }
  const currentLanguage = language || __guard__(me.get('aceConfig'), x => x.language) || 'python';
  let excludeCpp = 'cpp';
  if (!/```cpp\n[^`]+```\n?/.test(text)) {
    excludeCpp = 'javascript';
  }
  const excludedLanguages = _.without(['javascript', 'python', 'coffeescript', 'lua', 'java', 'cpp', 'html', 'io', 'clojure'], currentLanguage === 'cpp' ? excludeCpp : currentLanguage);
  // Exclude language-specific code blocks like ```python (... code ...)``
  // ` for each non-target language.
  const codeBlockExclusionRegex = new RegExp(`\`\`\`(${excludedLanguages.join('|')})\n[^\`]+\`\`\`\n?`, 'gm');
  // Exclude language-specific images like ![python - image description](image url) for each non-target language.
  const imageExclusionRegex = new RegExp(`!\\[(${excludedLanguages.join('|')}) - .+?\\]\\(.+?\\)\n?`, 'gm');
  text = text.replace(codeBlockExclusionRegex, '').replace(imageExclusionRegex, '');

  const commonLanguageReplacements = {
    python: [
      ['true', 'True'], ['false', 'False'], ['null', 'None'],
      ['object', 'dictionary'], ['Object', 'Dictionary'],
      ['array', 'list'], ['Array', 'List'],
    ],
    lua: [
      ['null', 'nil'],
      ['object', 'table'], ['Object', 'Table'],
      ['array', 'table'], ['Array', 'Table'],
    ]
  };
  for (var [from, to] of Array.from(commonLanguageReplacements[currentLanguage] != null ? commonLanguageReplacements[currentLanguage] : [])) {
    // Convert JS-specific keywords and types to Python ones, if in simple `code` tags.
    // This won't cover it when it's not in an inline code tag by itself or when it's not in English.
    text = text.replace(new RegExp(`\`${from}\``, 'g'), `\`${to}\``);
    // Now change "An `dictionary`" to "A `dictionary`", etc.
    if (startsWithVowel(from) && !startsWithVowel(to)) {
      text = text.replace(new RegExp(`( a|A)n( \`${to}\`)`, 'g'), "$1$2");
    }
    if (!startsWithVowel(from) && startsWithVowel(to)) {
      text = text.replace(new RegExp(`( a|A)( \`${to}\`)`, 'g'), "$1n$2");
    }
  }
  if ((currentLanguage === 'cpp') && (excludeCpp === 'javascript')) {
    const jsRegex = new RegExp("```javascript\n([^`]+)```", 'gm');
    text = text.replace(jsRegex, (a, l) => {
      return `\`\`\`cpp
  ${this.translateJS(a.slice(13, +(a.length-4) + 1 || undefined), 'cpp', false)}
\`\`\``;
    });
  }

  return text;
};

const makeErrorMessageTranslationRegex = function(englishString) {
  const escapeRegExp = str => // https://stackoverflow.com/questions/3446170/escape-string-for-use-in-javascript-regex
  str.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&");
  return new RegExp(escapeRegExp(englishString).replace(/\\\$\d/g, '(.+)').replace(/ +/g, ' +'));
};

export const translateErrorMessage = function({ message, errorCode, i18nParams, spokenLanguage, staticTranslations, translateFn }) {
  // Here we take a string from the locale file, find the placeholders ($1/$2/etc)
  //   and replace them with capture groups (.+),
  // returns a regex that will match against the error message
  //   and capture any dynamic values in the text
  // staticTranslations is { langCode: translations } for en and target languages
  // translateFn(i18nKey, i18nParams) is $.i18n.t on the client, i18next.t on the server
  let messages;
  if (!message) { return message; }
  if (/\n/.test(message)) { // Translate each line independently, since regexes act weirdly with newlines
    return message.split('\n').map(line => translateErrorMessage(
      { message: line.trim(), errorCode, i18nParams, spokenLanguage, staticTranslations, translateFn }
    )).join('\n');
  }

  if (/^i18n::/.test(message)) { // handle i18n messages from aether_worker
    messages = message.split('::');
    return translateFn(messages[1], JSON.parse(messages[2]));
  }

  message = message.replace(/([A-Za-z]+Error:) \1/, '$1');
  if (['en', 'en-US'].includes(spokenLanguage)) { return message; }

  // Separately handle line number and error type prefixes
  const applyReplacementTranslation = (text, regex, key) => {
    const fullKey = `esper.${key}`;
    const replacementTemplate = translateFn(fullKey);
    if (replacementTemplate === fullKey) { return; }
    // This carries over any capture groups from the regex into $N placeholders in the template string
    const replaced = text.replace(regex, replacementTemplate);
    if (replaced !== text) {
      return [replaced.replace(/``/g, '`'), true];
    }
    return [text, false];
  };

  // These need to be applied in this order, before the main text is translated
  const prefixKeys = ['line_no', 'uncaught', 'reference_error', 'argument_error', 'type_error', 'syntax_error', 'error'];

  messages = message.split(': ');
  for (var i in messages) {
    var m = messages[i];
    if (+i !== (messages.length - 1)) { m += ': '; } // i is string
    for (var keySet of [prefixKeys, Object.keys(_.omit(staticTranslations.en.esper), prefixKeys)]) {
      for (var translationKey of Array.from(keySet)) {
        var didTranslate;
        var englishString = staticTranslations.en.esper[translationKey];
        var regex = makeErrorMessageTranslationRegex(englishString);
        [m, didTranslate] = Array.from(applyReplacementTranslation(m, regex, translationKey));
        if (didTranslate && (keySet !== prefixKeys)) { break; }
      }
    }
    messages[i] = m;
  }

  if (errorCode) {
    messages[messages.length - 1] = translateFn(`esper.error_${(_.string || _.str).underscored(errorCode)}`, i18nParams);
  }

  return messages.join('');
};

// Note: These need to be double-escaped for insertion into regexes
var commentStarts = {
  javascript: '//',
  python: '#',
  coffeescript: '#',
  lua: '--',
  java: '//',
  cpp: '//',
  html: '<!--',
  css: '/\\*'
};

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}