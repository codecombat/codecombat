/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS204: Change includes calls to have a more natural evaluation order
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let Autocomplete;
import aceUtils from 'core/aceUtils';
import ace from 'lib/aceContainer';

const defaults = {
  autoLineEndings:
    // Mapping ace mode language to line endings to automatically insert
    // E.g. javascript: ";"
    {},
  basic: true,
  snippetsLangDefaults: true,
  liveCompletion: true,
  language: 'javascript',
  languagePrefixes: 'this.,@,self.',
  completers: {
    snippets: true
  }
};



// TODO: Should we be hooking in completers differently?
// TODO: https://github.com/ajaxorg/ace/blob/f133231df8c1f39156cc230ce31e66103ef4b1e2/lib/ace/ext/language_tools.js#L202

// TODO: Should show popup if we have a snippet match in Autocomplete.filterCompletions
// TODO: https://github.com/ajaxorg/ace/blob/695e24c41844c17fb2029f073d06338cd73ec33e/lib/ace/autocomplete.js#L449

// TODO: Create list of manual test cases

export default Autocomplete = (function() {
  let Tokenizer = undefined;
  let BackgroundTokenizer = undefined;
  Autocomplete = class Autocomplete {
    static initClass() {
      Tokenizer = '';
      BackgroundTokenizer = '';
    }

    constructor(aceEditor, options) {
      this.doLiveCompletion = this.doLiveCompletion.bind(this);
      this.onPopupFocusChange = this.onPopupFocusChange.bind(this);
      ({Tokenizer} = ace.require('ace/tokenizer'));
      ({BackgroundTokenizer} = ace.require('ace/background_tokenizer'));

      this.editor = aceEditor;
      const config = ace.require('ace/config');

      if (options == null) { options = {}; }

      const defaultsCopy = _.extend({}, defaults);
      this.options = _.merge(defaultsCopy, options);

      this.onPopupFocusChange = _.throttle(this.onPopupFocusChange, 25);

      //TODO: Renable option validation if we care
      //validationResult = optionsValidator @options
      //unless validationResult.valid
      //  throw new Error "Invalid Autocomplete options: " + JSON.stringify(validationResult.errors, null, 4)

      ace.config.loadModule('ace/ext/language_tools', () => {
        this.snippetManager = ace.require('ace/snippets').snippetManager;

        // Prevent tabbing a selection trigging an incorrect autocomplete
        // E.g. Given this.moveRight() selecting ".moveRight" from left to right and hitting tab yields this.this.moveRight()()
        // TODO: Figure out how to intercept this properly
        // TODO: Or, override expandSnippet command
        // TODO: Or, SnippetManager's expandSnippetForSelection
        this.snippetManager.expandWithTab = () => false;

        // Define a background tokenizer that constantly tokenizes the code
        const highlightRules = new (this.editor.getSession().getMode().HighlightRules)();
        const tokenizer = new Tokenizer(highlightRules.getRules());
        this.bgTokenizer = new BackgroundTokenizer(tokenizer, this.editor);
        const aceDocument = this.editor.getSession().getDocument();
        this.bgTokenizer.setDocument(aceDocument);
        this.bgTokenizer.start(0);

        this.setAceOptions();
        this.copyCompleters();
        this.activateCompleter();
        return this.editor.commands.on('afterExec', this.doLiveCompletion);
      });
    }

    destroy() {
      // Noticed a memory leak, so added a destroy function here
      this.editor.commands.off('afterExec', this.doLiveCompletion);  // Seems important to do
      __guardMethod__(this.bgTokenizer, 'stop', o => o.stop());  // Guessing
      if (this.oldSnippets != null) { return (this.snippetManager != null ? this.snippetManager.unregister(this.oldSnippets) : undefined); }  // Guessing
    }

    setAceOptions() {
      const aceOptions = {
        'enableLiveAutocompletion': this.options.liveCompletion,
        'enableBasicAutocompletion': this.options.basic,
        'enableSnippets': this.options.completers.snippets
      };

      this.editor.setOptions(aceOptions);
      return (this.editor.completer != null ? this.editor.completer.autoSelect = true : undefined);
    }

    copyCompleters() {
      this.completers = {snippets: {}, text: {}, keywords: {}};
      if (this.editor.completers != null) {
        [this.completers.snippets.comp, this.completers.text.comp, this.completers.keywords.comp] = Array.from(this.editor.completers);
      }
      if (this.options.completers.snippets) {
        this.completers.snippets = {pos: 0};
        // Replace the default snippet completer with our custom one
        return this.completers.snippets.comp = require('./snippets')(this.snippetManager, this.options.autoLineEndings);
      }
    }

    activateCompleter(comp) {
      if (Array.isArray(comp)) {
        return this.editor.completers = comp;
      } else if (typeof comp === 'string') {
        if ((this.completers[comp] != null) && (this.editor.completers[this.completers[comp].pos] !== this.completers[comp].comp)) {
          return this.editor.completers.splice(this.completers[comp].pos, 0, this.completers[comp].comp);
        }
      } else {
        this.editor.completers = [];
        return (() => {
          const result = [];
          for (var type in this.completers) {
            var comparator = this.completers[type];
            if (this.options.completers[type] === true) {
              result.push(this.activateCompleter(type));
            } else {
              result.push(undefined);
            }
          }
          return result;
        })();
      }
    }

    addSnippets(snippets, language) {
      this.options.language = language;
      return ace.config.loadModule('ace/ext/language_tools', () => {
        this.snippetManager = ace.require('ace/snippets').snippetManager;
        const snippetModulePath = 'ace/snippets/' + language;
        return ace.config.loadModule(snippetModulePath, m => {
          if (m != null) {
            this.snippetManager.files[language] = m;
            if ((m.snippets != null ? m.snippets.length : undefined) > 0) { this.snippetManager.unregister(m.snippets); }
            if (this.oldSnippets != null) { this.snippetManager.unregister(this.oldSnippets); }
            m.snippets = this.options.snippetsLangDefaults ? this.snippetManager.parseSnippetFile(m.snippetText) : [];
            for (var s of Array.from(snippets)) { m.snippets.push(s); }
            this.snippetManager.register(m.snippets);
            return this.oldSnippets = m.snippets;
          }
        });
      });
    }

    addCustomSnippets(snippets, language) {
      // add user custom identifiers. do not overwrite the codecombat snippets
      this.options.language = language;
      return ace.config.loadModule('ace/ext/language_tools', () => {
        this.snippetManager = ace.require('ace/snippets').snippetManager;
        const snippetModulePath = 'ace/snippets/' + language;
        return ace.config.loadModule(snippetModulePath, m => {
          if (m != null) {
            if (this.oldCustomSnippets != null) { this.snippetManager.unregister(this.oldCustomSnippets); }
            this.snippetManager.register(snippets);
            return this.oldCustomSnippets = snippets;
          }
        });
      });
    }

    setLiveCompletion(val) {
      if ((val === true) || (val === false)) {
        this.options.liveCompletion = val;
        return this.setAceOptions();
      }
    }

    set(setting, value) {
      switch (setting) {
        case 'snippets' || 'completers.snippets':
          if (typeof value !== 'boolean') { return; }
          this.options.completers.snippets = value;
          this.setAceOptions();
          this.activateCompleter('snippets');
          break;
        case 'basic':
          if (typeof value !== 'boolean') { return; }
          this.options.basic = value;
          this.setAceOptions();
          this.activateCompleter();
          break;
        case 'liveCompletion':
          if (typeof value !== 'boolean') { return; }
          this.options.liveCompletion = value;
          this.setAceOptions();
          this.activateCompleter();
          break;
        case 'language':
          if (typeof value !== 'string') { return; }
          this.options.language = value;
          this.setAceOptions();
          this.activateCompleter();
          break;
        case 'completers.keywords':
          if (typeof value !== 'boolean') { return; }
          this.options.completers.keywords = value;
          this.activateCompleter();
          break;
        case 'completers.text':
          if (typeof value !== 'boolean') { return; }
          this.options.completers.text = value;
          this.activateCompleter();
          break;
      }
    }

    on() { return this.paused = false; }
    off() { return this.paused = true; }

    doLiveCompletion(e) {
      // console.log 'Autocomplete doLiveCompletion', e
      if (!this.options.basic && !this.options.liveCompletion && !this.options.completers.snippets) { return; }
      if (this.paused) { return; }

      var TokenIterator = TokenIterator || ace.require('ace/token_iterator').TokenIterator;
      const {
        editor
      } = e;
      const text = e.args || "";
      const hasCompleter = editor.completer && editor.completer.activated;

      // We don't want to autocomplete with no prefix
      if ((e.command.name === "backspace") || (e.command.name === "insertstring")) {
        let pos = editor.getCursorPosition();
        const token = (new TokenIterator(editor.getSession(), pos.row, pos.column)).getCurrentToken();
        if (e.args === '\n') { // insert new line
          return Backbone.Mediator.publish('tome:completer-add-user-snippets', {});
        }
        if ((token != null) && !['comment'].includes(token.type)) {
          let prefix = this.getCompletionPrefix(editor);
          // Bake a fresh autocomplete every keystroke
          if (hasCompleter) { if (editor.completer != null) {
            editor.completer.detach();
          } }

          // Skip common single letter variable names
          if (/^x$|^y$/i.test(prefix)) { return; }

          // Only autocomplete if there's a prefix that can be matched
          if (prefix) {
            if (!editor.completer) {

              // Create new autocompleter
              ({
                Autocomplete
              } = ace.require('ace/autocomplete'));

              // Overwrite "Shift-Return" to Esc + Return instead
              // https://github.com/ajaxorg/ace/blob/695e24c41844c17fb2029f073d06338cd73ec33e/lib/ace/autocomplete.js#L208
              // TODO: Need a better way to update this command.  This is super shady.
              // TODO: Shift-Return errors when Autocomplete is open, dying on this call:
              // TODO: calls editor.completer.insertMatch(true) in lib/ace/autocomplete.js
              if (__guard__(Autocomplete != null ? Autocomplete.prototype : undefined, x => x.commands) != null) {
                const exitAndReturn = editor => {
                  // TODO: Execute a proper Return that selects the Autocomplete if open
                  editor.completer.detach();
                  return this.editor.insert("\n");
                };
                Autocomplete.prototype.commands["Shift-Return"] = exitAndReturn;
              }

              editor.completer = new Autocomplete();
              const {
                getCompletionPrefix
              } = this;
              editor.completer.gatherCompletions = function(editor, callback) {
                const session = editor.getSession();
                pos = editor.getCursorPosition();

                prefix = getCompletionPrefix(editor);

                this.base = session.doc.createAnchor(pos.row, pos.column - prefix.length);
                this.base.$insertRight = true;

                let matches = [];
                let total = editor.completers.length;
                editor.completers.forEach((completer, i) => {
                  return completer.getCompletions(editor, session, pos, prefix, (err, results) => {
                    if (!err && results) {
                      matches = matches.concat(results);
                    }
                    // Fetch prefix again, because they may have changed by now
                    return callback(null, {
                      prefix: getCompletionPrefix(editor),
                      matches,
                      finished: (--total === 0)
                    });
                  });
                });
                return true;
              };
            }

            // Disable autoInsert and show popup
            editor.completer.autoSelect = true;
            editor.completer.autoInsert = false;
            editor.completer.showPopup(editor);

            // Hide popup if too many suggestions
            // TODO: Completions aren't asked for unless we show popup, so this is super hacky
            // TODO: Backspacing to yield more suggestions does not close popup
            if (__guard__(__guard__(editor.completer != null ? editor.completer.completions : undefined, x2 => x2.filtered), x1 => x1.length) > 50) {
              editor.completer.detach();

            // Update popup CSS after it's been launched
            // TODO: Popup has original CSS on first load, and then visibly/weirdly changes based on these updates
            // TODO: Find better way to extend popup.
            } else if (editor.completer.popup != null) {
              $('.ace_autocomplete').find('.ace_content').css('cursor', 'pointer');
              if (this.options.popupFontSizePx != null) { $('.ace_autocomplete').css('font-size', this.options.popupFontSizePx + 'px'); }
              if (this.options.popupLineHeightPx != null) { $('.ace_autocomplete').css('line-height', this.options.popupLineHeightPx + 'px'); }
              if (this.options.popupWidthPx != null) { $('.ace_autocomplete').css('width', this.options.popupWidthPx + 'px'); }
              if (typeof editor.completer.popup.resize === 'function') {
                editor.completer.popup.resize();
              }
              editor.completer.popup.on("mousemove", this.onPopupFocusChange(editor, TokenIterator));
            }
          }
        }
      }

              // TODO: Can't change padding before resize(), but changing it afterwards clears new padding
              // TODO: Figure out how to hook into events rather than using setTimeout()
              // fixStuff = =>
              //   $('.ace_autocomplete').find('.ace_line').css('color', 'purple')
              //   $('.ace_autocomplete').find('.ace_line').css('padding', '20px')
              //   # editor.completer.popup.resize?(true)
              // setTimeout fixStuff, 1000

      // Update tokens for text completer
      if (this.options.completers.text && ['backspace', 'del', 'insertstring', 'removetolinestart', 'Enter', 'Return', 'Space', 'Tab'].includes(e.command.name)) {
        return this.bgTokenizer.fireUpdateEvent(0, this.editor.getSession().getLength());
      }
    }

    onPopupFocusChange(editor, TokenIterator) {
      return e => {
        let markerRange;
        const pos = e.getDocumentPosition();
        const it = new TokenIterator(editor.completer.popup.session, pos.row, pos.column);
        let word = null;
        if (it.getCurrentTokenRow() === pos.row) {
          const line = editor.completer.completions.filtered[pos.row].caption;
          const [fun, params] = Array.from(line.split('('));
          const prefixParts = fun.split(/[.:]/g);
          word = prefixParts.slice(-1)[0];
          markerRange = new Range(pos.row, pos.column, pos.row, pos.column + word.length);
        }
        return Backbone.Mediator.publish('tome:completer-popup-focus-change', {word, markerRange});
      };
    }

    getCompletionPrefix(editor) {
      // TODO: this is not used to get prefix that is passed to completer.getCompletions
      // TODO: Autocomplete.gatherCompletions is using this (no regex 3rd param):
      // TODO: var prefix = util.retrievePrecedingIdentifier(line, pos.column);
      var util = util || ace.require('ace/autocomplete/util');
      const pos = editor.getCursorPosition();
      const line = editor.session.getLine(pos.row);
      let prefix = null;
      if (editor.completers != null) {
        editor.completers.forEach(function(completer) {
        if (completer != null ? completer.identifierRegexps : undefined) {
          return completer.identifierRegexps.forEach(function(identifierRegex) {
            if (!prefix && identifierRegex) {
              return prefix = util.retrievePrecedingIdentifier(line, pos.column, identifierRegex);
            }
          });
        }
      });
      }

      const identifierRegex = /['"\.a-zA-Z_0-9\$\-\u00A2-\uFFFF]/;
      if (prefix == null) { prefix = util.retrievePrecedingIdentifier(line, pos.column, identifierRegex); }
      return prefix;
    }

    addCodeCombatSnippets(level, spellView, e) {
      let attackEntry, content, doc, entry, left, name;
      const snippetEntries = [];
      const source = spellView.getSource();
      let haveFindNearestEnemy = false;
      let haveFindNearest = false;
      const autocompleteReplacement = (left = level.get("autocompleteReplacement")) != null ? left : [];
      let usedAutocompleteReplacement = [];

      const fixLanguageSnippets = function(doc, lang) {
        let content, name;
        usedAutocompleteReplacement = [];

        if (['java', 'cpp'].includes(lang) && !__guard__(doc != null ? doc.snippets : undefined, x => x[lang]) && __guard__(doc != null ? doc.snippets : undefined, x1 => x1.javascript)) {
          doc.snippets[lang] = doc.snippets.javascript;
        }

        if (['lua', 'coffeescript', 'python'].includes(lang) && !__guard__(doc != null ? doc.snippets : undefined, x2 => x2[lang]) && (__guard__(doc != null ? doc.snippets : undefined, x3 => x3.python) || __guard__(doc != null ? doc.snippets : undefined, x4 => x4.javascript))) {
            // These are mostly the same, so use the Python or JavaScript ones if language-specific ones aren't available
          doc.snippets[lang] = __guard__(doc != null ? doc.snippets : undefined, x5 => x5.python) || doc.snippets.javascript;
        }

        if (__guard__(doc != null ? doc.snippets : undefined, x6 => x6[lang])) {
          ({
            name
          } = doc);
          const replacement = _.find(autocompleteReplacement, el => el.name === name);
          if (replacement) {
            usedAutocompleteReplacement.push(replacement.name);
          }
          content = __guard__(__guard__(replacement != null ? replacement.snippets : undefined, x8 => x8[lang]), x7 => x7.code) || doc.snippets[lang].code;
          if (/loop/.test(content) && level.get('moveRightLoopSnippet')) {
            // Replace default loop snippet with an embedded moveRight()
            content = (() => { switch (lang) {
              case 'python': return 'while True:\n    hero.moveRight()\n    ${1:}';
              case 'javascript': case 'java': case 'cpp': return 'while (true) {\n    hero.moveRight();\n    ${1:}\n}';
              default: return content;
            } })();
          }
          if (/loop/.test(content) && level.isType('course', 'course-ladder')) {
            // Temporary hackery to make it look like we meant while True: in our loop snippets until we can update everything
            content = (() => { switch (lang) {
              case 'python': return content.replace(/loop:/, 'while True:');
              case 'javascript': case 'java': case 'cpp': return content.replace(/loop/, 'while (true)');
              case 'lua': return content.replace(/loop/, 'while true then');
              case 'coffeescript': return content;
              default: return content;
            } })();
            name = (() => { switch (lang) {
              case 'python': return 'while True';
              case 'coffeescript': return 'loop';
              default: return 'while true';
            } })();
          }
          // For now, update autocomplete to use hero instead of self/this, if hero is already used in the source.
          // Later, we should make this happen all the time - or better yet update the snippets.
          if (/hero/.test(source) || !/(self[\.\:]|this\.|\@)/.test(source)) {
            const thisToken = {
              'python': /self/,
              'javascript': /this/,
              'java': /this/,
              'cpp': /this/,
              'lua': /self/
            };
            if (thisToken[lang] && thisToken[lang].test(content)) {
              content = content.replace(thisToken[lang], 'hero');
            }
          }
        }
        return {doc, content, name};
      };

      for (var group in e.propGroups) {
        var props = e.propGroups[group];
        for (var prop of Array.from(props)) {
          var left1, owner;
          if (_.isString(prop)) {  // organizePalette
            owner = group;
          } else {                // organizePaletteHero
            ({
              owner
            } = prop);
            ({
              prop
            } = prop);
          }
          doc = _.find(((left1 = e.allDocs['__' + prop]) != null ? left1 : []), function(doc) {
            if (doc.owner === owner) { return true; }
            return ((owner === 'this') || (owner === 'more')) && ((doc.owner == null) || (doc.owner === 'this'));
          });

          ({doc, content, name} = fixLanguageSnippets(doc, e.language));

          if (__guard__(doc != null ? doc.snippets : undefined, x => x[e.language])) {
            entry = {
              content,
              meta: $.i18n.t('keyboard_shortcuts.press_enter', {defaultValue: 'press enter'}),
              name,
              tabTrigger: doc.snippets[e.language].tab,
              importance: doc.autoCompletePriority != null ? doc.autoCompletePriority : 1.0
            };
            if (!haveFindNearestEnemy) { haveFindNearestEnemy = name === 'findNearestEnemy'; }
            if (!haveFindNearest) { haveFindNearest = name === 'findNearest'; }
            if (name === 'attack') {
              // Postpone this until we know if findNearestEnemy is available
              attackEntry = entry;
            } else {
              snippetEntries.push(entry);
            }

            if (doc.userShouldCaptureReturn) {
              var varName = doc.userShouldCaptureReturn.variableName != null ? doc.userShouldCaptureReturn.variableName : 'result';
              var type = doc.userShouldCaptureReturn.type != null ? doc.userShouldCaptureReturn.type[e.language] : undefined;
              if (type == null) { type = (() => { switch (e.language) {
                case 'javascript': case 'java': return 'var';
                case 'cpp': return 'auto';
                case 'lua': return 'local';
                default: return '';
              } })(); }
              entry.captureReturn = (() => { switch (e.language) {
                case 'javascript': case 'java': case 'cpp': case 'lua': return type + ' ' + varName + ' = ';
                default: return varName + ' = ';
              } })();
            }
          }
        }
      }

      // TODO: Generalize this snippet replacement
      // TODO: Where should this logic live, and what format should it be in?
      if (attackEntry != null) {
        let needle;
        if (!haveFindNearestEnemy && !haveFindNearest && (needle = level.get('slug'), !['known-enemy', 'course-known-enemy'].includes(needle))) {
          // No findNearestEnemy, so update attack snippet to string-based target
          // (On Known Enemy, we are introducing enemy2 = "Gert", so we want them to do attack(enemy2).)
          attackEntry.content = attackEntry.content.replace('${1:enemy}', '"${1:Enemy Name}"');
        }
        snippetEntries.push(attackEntry);
      }

      // Update 'hero.' and 'game.' entries to include their prefixes
      for (entry of Array.from(snippetEntries)) {
        if (((entry.content != null ? entry.content.indexOf('hero.') : undefined) === 0) && ((entry.name != null ? entry.name.indexOf('hero.') : undefined) < 0)) {
          entry.name = `hero.${entry.name}`;
        } else if (((entry.content != null ? entry.content.indexOf('game.') : undefined) === 0) && ((entry.name != null ? entry.name.indexOf('game.') : undefined) < 0)) {
          entry.name = `game.${entry.name}`;
        }
      }

      if (haveFindNearest && !haveFindNearestEnemy) {
        spellView.translateFindNearest();
      }

      for (var replacement of Array.from(autocompleteReplacement)) {
        if (Array.from(usedAutocompleteReplacement).includes(replacement.name)) { continue; }
        if (!replacement.snippets) { continue; }

        // in case level.get('autocompeteReplacement') is defined and without full-language snippets
        ({doc, content, name} = fixLanguageSnippets(replacement, e.language));

        entry = {
          content,
          meta: $.i18n.t('keyboard_shortcuts.press_enter', {defaultValue: 'press enter'}),
          name,
          tabTrigger: __guard__(doc.snippets != null ? doc.snippets[e.language] : undefined, x1 => x1.tab),
          importance: doc.autoCompletePriority != null ? doc.autoCompletePriority : 1.0
        };
        snippetEntries.push(entry);
      }

      // window.AutocompleteInstance = @Autocomplete  # For debugging. Make sure to not leave active when committing.
      // window.snippetEntries = snippetEntries
      const lang = aceUtils.aceEditModes[e.language].substr('ace/mode/'.length);
      this.addSnippets(snippetEntries, lang);
      spellView.editorLang = lang;
      return snippetEntries;
    }
  };
  Autocomplete.initClass();
  return Autocomplete;
})();

function __guardMethod__(obj, methodName, transform) {
  if (typeof obj !== 'undefined' && obj !== null && typeof obj[methodName] === 'function') {
    return transform(obj, methodName);
  } else {
    return undefined;
  }
}
function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}