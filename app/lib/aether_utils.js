// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
require('./aether/aether')

Aether.addGlobal('Vector', require('./world/vector'));
Aether.addGlobal('_', _);
const translateUtils = require('./translate-utils');

module.exports.createAetherOptions = function(options) {
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

module.exports.generateSpellsObject = function(options) {
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

module.exports.replaceSimpleLoops = function(source, language) {
  switch (language) {
    case 'python': return source.replace(/loop:/, 'while True:');
    case 'javascript': case 'java': case 'cpp': return source.replace(/loop {/, 'while (true) {');
    case 'lua': return source.replace(/loop\n/, 'while true do\n');
    case 'coffeescript': return source;
    default: return source;
  }
};

const startsWithVowel = s => Array.from('aeiouAEIOU').includes(s[0]);

module.exports.filterMarkdownCodeLanguages = function(text, language) {
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
  ${translateUtils.translateJS(a.slice(13, +(a.length-4) + 1 || undefined), 'cpp', false)}
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

module.exports.translateErrorMessage = function({ message, errorCode, i18nParams, spokenLanguage, staticTranslations, translateFn }) {
  // Here we take a string from the locale file, find the placeholders ($1/$2/etc)
  //   and replace them with capture groups (.+),
  // returns a regex that will match against the error message
  //   and capture any dynamic values in the text
  // staticTranslations is { langCode: translations } for en and target languages
  // translateFn(i18nKey, i18nParams) is $.i18n.t on the client, i18next.t on the server
  let messages;
  if (!message) { return message; }
  if (/\n/.test(message)) { // Translate each line independently, since regexes act weirdly with newlines
    return message.split('\n').map(line => module.exports.translateErrorMessage({ message: line.trim(), errorCode, i18nParams, spokenLanguage, staticTranslations, translateFn })).join('\n');
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

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}