/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
// These were extracted out of utils.coffee to prevent everything from having Ace as a dependency.

const ace = require('lib/aceContainer');
const {
  TokenIterator
} = ace.require('ace/token_iterator');

const aceEditModes = {
  javascript: 'ace/mode/javascript',
  coffeescript: 'ace/mode/coffee',
  python: 'ace/mode/python',
  lua: 'ace/mode/lua',
  java: 'ace/mode/java',
  cpp: 'ace/mode/c_cpp',
  html: 'ace/mode/html'
};

// These ACEs are used for displaying code snippets statically, like in SpellPaletteEntryView popovers
// and have short lifespans
const initializeACE = function(el, codeLanguage) {
  const contents = $(el).text().trim();
  const editor = ace.edit(el);
  editor.setOptions({maxLines: Infinity});
  editor.setReadOnly(true);
  editor.setTheme('ace/theme/textmate');
  editor.setShowPrintMargin(false);
  editor.setShowFoldWidgets(false);
  editor.setHighlightActiveLine(false);
  editor.setHighlightActiveLine(false);
  editor.setBehavioursEnabled(false);
  editor.renderer.setShowGutter(false);
  editor.setValue(contents);
  editor.clearSelection();
  const session = editor.getSession();
  session.setUseWorker(false);
  session.setMode(aceEditModes[codeLanguage]);
  session.setWrapLimitRange(null);
  session.setUseWrapMode(true);
  session.setNewLineMode('unix');
  return editor;
};

const identifierRegex = function(lang, type) {
  if (type === 'function') {
    const regexs = {
      python: /def ([a-zA-Z_0-9\$\-\u00A2-\uFFFF]+\s*\(?[^)]*\)?):/,
      javascript: /function ([a-zA-Z_0-9\$\-\u00A2-\uFFFF]+\s*\(?[^)]*\)?)/,
      cpp: /[a-z]+\s+([a-zA-Z_0-9\$\-\u00A2-\uFFFF]+\s*\(?[^)]*\)?)/,
      java: /[a-z]+\s+([a-zA-Z_0-9\$\-\u00A2-\uFFFF]+\s*\(?[^)]*\)?)/
    };
    if (lang in regexs) {
      return regexs[lang];
    }
    return /./;
  } else if (type === 'properties') {
    return /\.([a-zA-Z_0-9\$\-\u00A2-\uFFFF]+)/g;
  }
  return /./;
};

const singleLineCommentRegex = function(lang) {
  let commentStart;
  const commentStarts = {
    javascript: '//',
    python: '#',
    coffeescript: '#',
    lua: '--',
    java: '//',
    cpp: '//',
    html: '<!--',
    css: '/\\*'
  };

  if (lang === 'html') {
    commentStart = `${commentStarts.html}|${commentStarts.css}|${commentStarts.javascript}`;
  } else {
    commentStart = commentStarts[lang] || '//';
  }
  return new RegExp(`[ \t]*(${commentStart})[^\"'\n]*`);
};

const parseUserSnippets = function(source, lang, session) {
  const replaceParams = function(str) {
    let i = 1;
    str = str.replace(/(?:[^(,)]+ )?([a-zA-Z-0-9\$\-\u00A2-\uFFFF]+)([^,)]*)/g, "${:$1}"); // /(?:[^(,)]+ )?/ part for ignoring the type declaration in cpp/java
    const reg = /\$\{:/;
    while (reg.test(str)) {
      str = str.replace(reg, `\${${i}:`);
      i += 1;
    }
    return str;
  };

  const makeEntry = function(name, content, importance) {
    let entry;
    content = content != null ? content : name;
    return entry = {
      meta: $.i18n.t('keyboard_shortcuts.press_enter', {defaultValue: 'press enter'}),
      importance: importance != null ? importance : 5,
      content,
      name,
      tabTrigger: name
    };
  };

  const userSnippets = [];
  const allIdentifiers = {};
  const newIdentifiers = {};

  const it = new TokenIterator(session, 0, 0);
  let next = it.getCurrentToken();
  if (!next) { next = it.stepForward(); }
  while (next) {
    if (next.type === 'string') {
      if (!(next.value in newIdentifiers)) {
        newIdentifiers[next.value] = makeEntry(next.value);
      } else {
        newIdentifiers[next.value].importance *= 2;
      }
    }
    if (next.type === 'identifier') {
      if (next.value.length === 1) { // skip single char variables
        next = it.stepForward();
        continue;
      }
      if (!(next.value in allIdentifiers)) {
        allIdentifiers[next.value] = 5;
      } else {
        allIdentifiers[next.value] *= 2;
      }
    }
    // console.log("deubg next:", next)
    next = it.stepForward();
  }

  const lines = source.split('\n');
  lines.forEach(line => {
    if (singleLineCommentRegex(lang).test(line)) {
      return;
    }

    let match = identifierRegex(lang, 'function').exec(line);
    if (match && match[1]) {
      let [fun, params] = Array.from(match[1].split('('));
      params = '(' + params;
      if (!(fun in newIdentifiers)) {
        newIdentifiers[fun] = makeEntry(match[1], fun + replaceParams(params), allIdentifiers[fun]);
        delete allIdentifiers[fun];
      }
    }
    const propertiesRegex = identifierRegex(lang, 'properties');
    return (() => {
      const result = [];
      while ((match = propertiesRegex.exec(line))) {
        if (match[1] in allIdentifiers) {
          result.push(delete allIdentifiers[match[1]]);
        } else {
          result.push(undefined);
        }
      }
      return result;
    })();
  });
  for (var id in allIdentifiers) {
    var importance = allIdentifiers[id];
    if ((id === 'hero') && (importance <= 20)) { // if hero doesn't appears more than twice
      continue;
    }
    newIdentifiers[id] = makeEntry(id, id, importance);
  }

  // console.log 'debug newIdentifiers: ', newIdentifiers
  return newIdentifiers;
};
  // @autocomplete.addCustomSnippets Object.values(newIdentifiers), lang

module.exports = {
  aceEditModes,
  initializeACE,
  parseUserSnippets
};
