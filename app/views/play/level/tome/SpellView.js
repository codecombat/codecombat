/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS202: Simplify dynamic range loops
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let SpellView;
require('app/styles/play/level/tome/spell.sass');
const CocoView = require('views/core/CocoView');
const template = require('app/templates/play/level/tome/spell');
const {me} = require('core/auth');
const filters = require('lib/image_filter');
const ace = require('lib/aceContainer');
let {
  Range
} = ace.require('ace/range');
const {
  UndoManager
} = ace.require('ace/undomanager');
const Problem = require('./Problem');
const SpellDebugView = require('./SpellDebugView');
const SpellTranslationView = require('./SpellTranslationView');
const SpellToolbarView = require('./SpellToolbarView');
const LevelComponent = require('models/LevelComponent');
const UserCodeProblem = require('models/UserCodeProblem');
const aceUtils = require('core/aceUtils');
const blocklyUtils = require('core/blocklyUtils');
const CodeLog = require('models/CodeLog');
const Autocomplete = require('./editor/autocomplete');
const {
  TokenIterator
} = ace.require('ace/token_iterator');
const LZString = require('lz-string');
const utils = require('core/utils');
const Aether = require('lib/aether/aether');
const Blockly = require('blockly');
const storage = require('core/storage');
const AceDiff = require('ace-diff');
const globalVar = require('core/globalVar');
const fetchJson = require('core/api/fetch-json');
const store = require('core/store');
require('app/styles/play/level/tome/ace-diff-spell.sass');

module.exports = (SpellView = (function() {
  SpellView = class SpellView extends CocoView {
    static initClass() {
      this.prototype.id = 'spell-view';
      this.prototype.className = 'shown';
      this.prototype.template = template;
      this.prototype.controlsEnabled = true;
      this.prototype.eventsSuppressed = true;
      this.prototype.writable = true;
      this.prototype.languagesThatUseWorkers = ['html'];

      this.prototype.keyBindings = {
        'default': null,
        'vim': 'ace/keyboard/vim',
        'emacs': 'ace/keyboard/emacs'
      };

      this.prototype.subscriptions = {
        'level:disable-controls': 'onDisableControls',
        'level:enable-controls': 'onEnableControls',
        'surface:frame-changed': 'onFrameChanged',
        'surface:coordinate-selected': 'onCoordinateSelected',
        'god:new-world-created': 'onNewWorld',
        'god:user-code-problem': 'onUserCodeProblem',
        'god:non-user-code-problem': 'onNonUserCodeProblem',
        'tome:manual-cast': 'onManualCast',
        'tome:spell-changed': 'onSpellChanged',
        'tome:spell-created': 'onSpellCreated',
        'tome:completer-add-user-snippets': 'onAddUserSnippets',
        'level:session-will-save': 'onSessionWillSave',
        'modal:closed': 'focus',
        'tome:focus-editor': 'focus',
        'tome:spell-statement-index-updated': 'onStatementIndexUpdated',
        'tome:change-language': 'onChangeLanguage',
        'tome:change-config': 'onChangeEditorConfig',
        'tome:update-snippets': 'addAutocompleteSnippets',
        'tome:insert-snippet': 'onInsertSnippet',
        'tome:spell-beautify': 'onSpellBeautify',
        'tome:maximize-toggled': 'onMaximizeToggled',
        'tome:toggle-blocks': 'onToggleBlocks',
        'tome:problems-updated': 'onProblemsUpdated',
        'script:state-changed': 'onScriptStateChange',
        'playback:ended-changed': 'onPlaybackEndedChanged',
        'level:contact-button-pressed': 'onContactButtonPressed',
        'level:show-victory': 'onShowVictory',
        'web-dev:error': 'onWebDevError',
        'tome:palette-updated': 'onPaletteUpdated',
        'level:gather-chat-message-context': 'onGatherChatMessageContext',
        'tome:fix-code': 'onFixCode',
        'level:update-solution': 'onUpdateSolution',
        'level:toggle-solution': 'onToggleSolution',
        'level:close-solution': 'closeSolution',
        'level:streaming-solution': 'onStreamingSolution',
        'websocket:asking-help': 'onAskingHelp'
      };

      this.prototype.events =
        {'mouseout': 'onMouseOut'};
    }

    constructor(options) {
      super(options)
      this.blocklyToAce = this.blocklyToAce.bind(this);
      this.aceToBlockly = this.aceToBlockly.bind(this);
      this.onAllLoaded = this.onAllLoaded.bind(this);
      this.notifySpellChanged = this.notifySpellChanged.bind(this);
      this.notifyEditingEnded = this.notifyEditingEnded.bind(this);
      this.notifyEditingBegan = this.notifyEditingBegan.bind(this);
      this.updateSolutionLines = this.updateSolutionLines.bind(this);
      this.updateAceLines = this.updateAceLines.bind(this);
      this.updateLines = this.updateLines.bind(this);
      this.saveSpade = this.saveSpade.bind(this);
      this.onCursorActivity = this.onCursorActivity.bind(this);
      this.updateHTML = this.updateHTML.bind(this);
      this.fetchToken = this.fetchToken.bind(this);
      this.fetchTokenForSource = this.fetchTokenForSource.bind(this);
      this.updateAether = this.updateAether.bind(this);
      this.onAceMouseMove = this.onAceMouseMove.bind(this);
      this.highlightCurrentLine = this.highlightCurrentLine.bind(this);
      this.onGutterClick = this.onGutterClick.bind(this);
      this.toggleBackground = this.toggleBackground.bind(this);
      this.onWindowResize = this.onWindowResize.bind(this);
      this.checkRequiredCode = this.checkRequiredCode.bind(this);
      this.checkSuspectCode = this.checkSuspectCode.bind(this);
      // this.supermodel = options.supermodel;
      this.worker = options.worker;
      this.session = options.session;
      this.spell = options.spell;
      this.courseID = options.courseID;
      this.problems = [];
      this.savedProblems = {}; // Cache saved user code problems to prevent duplicates
      if (!Array.from(this.spell.permissions.readwrite).includes(me.team)) { this.writable = false; }  // TODO: make this do anything
      this.highlightCurrentLine = _.throttle(this.highlightCurrentLine, 100);
      $(window).on('resize', this.onWindowResize);
      this.observing = this.session.get('creator') !== me.id;
      this.spectateView = options.spectateView;
      this.loadedToken = {};
      this.addUserSnippets = _.debounce(this.reallyAddUserSnippets, 500, {maxWait: 1500, leading: true, trailing: false});
      this.teaching = utils.getQueryVariable('teaching', false);
      this.urlSession = utils.getQueryVariable('session');
    }

    afterRender() {
      super.afterRender();
      this.createACE();
      this.createACEShortcuts();
      this.hookACECustomBehavior();
      if ((me.isAdmin() || utils.getQueryVariable('ai')) && !this.spectateView) {
        this.fillACESolution();
      }
      if (this.teaching) {
        this.fillACESolution();
      }
      this.fillACE();
      this.createOnCodeChangeHandlers();
      this.lockDefaultCode();
      return _.defer(this.onAllLoaded);  // Needs to happen after the code generating this view is complete
    }

    // This ACE is used for the code editor, and is only instantiated once per level.
    createACE() {
      // Test themes and settings here: http://ace.ajax.org/build/kitchen-sink.html
      let left;
      const aceConfig = (left = me.get('aceConfig')) != null ? left : {};
      this.destroyAceEditor(this.ace);
      this.ace = ace.edit(this.$el.find('.ace')[0]);
      this.aceSession = this.ace.getSession();
      // Override setAnnotations so the Ace html worker doesn't clobber our annotations
      this.reallySetAnnotations = this.aceSession.setAnnotations.bind(this.aceSession);
      this.aceSession.setAnnotations = annotations => {
        const previousAnnotations = this.aceSession.getAnnotations();
        const newAnnotations = _.filter(previousAnnotations, annotation => annotation.createdBy != null) // Keep the ones we generated
          .concat(_.reject(annotations, annotation => // Ignore this particular info-annotation the html worker generates
        annotation.text === 'Start tag seen without seeing a doctype first. Expected e.g. <!DOCTYPE html>.')
        );
        return this.reallySetAnnotations(newAnnotations);
      };
      this.aceDoc = this.aceSession.getDocument();
      this.aceSession.setUseWorker(Array.from(this.languagesThatUseWorkers).includes(this.spell.language));
      this.aceSession.setMode(aceUtils.aceEditModes[this.spell.language]);
      this.aceSession.setWrapLimitRange(null);
      this.aceSession.setUseWrapMode(true);
      this.aceSession.setNewLineMode('unix');
      this.aceSession.setUseSoftTabs(true);
      this.ace.setTheme('ace/theme/textmate');
      this.ace.setDisplayIndentGuides(false);
      this.ace.setShowPrintMargin(false);
      this.ace.setShowInvisibles(false);
      this.ace.setBehavioursEnabled(aceConfig.behaviors);
      this.ace.setAnimatedScroll(true);
      this.ace.setShowFoldWidgets(false);
      this.ace.setKeyboardHandler(this.keyBindings[aceConfig.keyBindings != null ? aceConfig.keyBindings : 'default']);
      this.ace.$blockScrolling = Infinity;
      this.ace.on('mousemove', this.onAceMouseMove);
      this.ace.on('mouseout', this.onAceMouseOut);
      this.toggleControls(null, this.writable);
      this.aceSession.selection.on('changeCursor', this.onCursorActivity);
      $(this.ace.container).find('.ace_gutter').on('click mouseenter', '.ace_error, .ace_warning, .ace_info', this.onAnnotationClick);
      $(this.ace.container).find('.ace_gutter').on('click', this.onGutterClick);
      let liveCompletion = aceConfig.liveCompletion != null ? aceConfig.liveCompletion : true;
      const classroomLiveCompletion = (this.options.classroomAceConfig != null ? this.options.classroomAceConfig : {liveCompletion: true}).liveCompletion;
      liveCompletion = classroomLiveCompletion && liveCompletion;
      this.initAutocomplete(liveCompletion);

      if (this.teaching) {
        console.log('connect provider:', this.urlSession);
        this.yjsProvider = aceUtils.setupCRDT(`${this.urlSession}`, me.broadName(), '', this.ace);
        this.yjsProvider.connections = 1;
        this.yjsProvider.awareness.on('change', () => {
          console.log("provider get connections? ", this.yjsProvider.awareness.getStates().size);
          return this.yjsProvider.connections = this.yjsProvider.awareness.getStates().size;
        });
      }

      if ((this.session.get('creator') !== me.id) || this.session.fake) { return; }
      // Create a Spade to 'dig' into Ace.
      this.spade = new Spade();
      this.spade.track(this.ace);
      this.spade.createUIEvent("spade-created");
      // If a user is taking longer than 10 minutes, let's log it.
      let saveSpadeDelay = 10 * 60 * 1000;
      if (this.options.level.get('releasePhase') === 'beta') {
        saveSpadeDelay = 3 * 60 * 1000;  // Capture faster for beta levels, to be more likely to get something
      } else if ((Math.random() < 0.05) && _.find(utils.freeAccessLevels, {access: 'short', slug: this.options.level.get('slug')})) {
        saveSpadeDelay = 3 * 60 * 1000;  // Capture faster for some free levels to compare with beta levels
      }
      return this.saveSpadeTimeout = setTimeout(this.saveSpade, saveSpadeDelay);
    }

    createACEShortcuts() {
      let aceCommands;
      this.aceCommands = (aceCommands = []);
      const addCommand = c => {
        this.ace.commands.addCommand(c);
        return aceCommands.push(c.name);
      };
      addCommand({
        name: 'run-code',
        bindKey: {win: 'Shift-Enter|Ctrl-Enter', mac: 'Shift-Enter|Command-Enter|Ctrl-Enter'},
        exec: () => Backbone.Mediator.publish('tome:manual-cast', {realTime: this.options.level.isType('game-dev')})});
      if (!this.observing) {
        addCommand({
          name: 'run-code-real-time',
          bindKey: {win: 'Ctrl-Shift-Enter', mac: 'Command-Shift-Enter|Ctrl-Shift-Enter'},
          exec: () => {
            let timeUntilResubmit;
            const doneButton = this.$('.done-button:visible');
            if (doneButton.length) {
              return doneButton.trigger('click');
            } else if (this.options.level.get('replayable') && ((timeUntilResubmit = this.session.timeUntilResubmit()) > 0)) {
              return Backbone.Mediator.publish('tome:manual-cast-denied', {timeUntilResubmit});
            } else {
              return Backbone.Mediator.publish('tome:manual-cast', {realTime: true});
            }
          }});
      }
      addCommand({
        name: 'no-op',
        bindKey: {win: 'Ctrl-S', mac: 'Command-S|Ctrl-S'},
        exec() {}
      });  // just prevent page save call
      addCommand({
        name: 'previous-line',
        bindKey: {mac: 'Ctrl-P'},
        passEvent: true,
        exec: () => this.ace.execCommand('golineup')
      });  // stop trying to jump to matching paren, I want default Mac/Emacs previous line
      addCommand({
        name: 'toggle-playing',
        bindKey: {win: 'Ctrl-P', mac: 'Command-P'},
        readOnly: true,
        exec() { return Backbone.Mediator.publish('level:toggle-playing', {}); }});
      addCommand({
        name: 'end-current-script',
        bindKey: {win: 'Shift-Space', mac: 'Shift-Space'},
        readOnly: true,
        exec: () => {
          if (this.scriptRunning) {
            return Backbone.Mediator.publish('level:shift-space-pressed', {});
          } else {
            return this.ace.insert(' ');
          }
        }
      });
      addCommand({
        name: 'end-all-scripts',
        bindKey: {win: 'Escape', mac: 'Escape'},
        readOnly: true,
        exec() {
          return Backbone.Mediator.publish('level:escape-pressed', {});
        }});
      addCommand({
        name: 'unfocus-editor',
        bindKey: {win: 'Escape', mac: 'Escape'},
        readOnly: true,
        exec() {
          if (!utils.isOzaria) { return; }
          // In screen reader mode, we need to move focus to next element on escape, since tab won't.
          // Next element happens to be #run button, or maybe #update-code button in game-dev.
          // We need this even when you're not in screen reader mode, so you can tab over to enable it.
          if ($(document.activeElement).hasClass('ace_text-input')) {
            return $('#run, #update-code').focus();
          }
        }
      });
      addCommand({
        name: 'toggle-grid',
        bindKey: {win: 'Ctrl-G', mac: 'Command-G|Ctrl-G'},
        readOnly: true,
        exec() { return Backbone.Mediator.publish('level:toggle-grid', {}); }});
      addCommand({
        name: 'toggle-debug',
        bindKey: {win: 'Ctrl-\\', mac: 'Command-\\|Ctrl-\\'},
        readOnly: true,
        exec() { return Backbone.Mediator.publish('level:toggle-debug', {}); }});
      addCommand({
        name: 'toggle-pathfinding',
        bindKey: {win: 'Ctrl-O', mac: 'Command-O|Ctrl-O'},
        readOnly: true,
        exec() { return Backbone.Mediator.publish('level:toggle-pathfinding', {}); }});
      addCommand({
        name: 'level-scrub-forward',
        bindKey: {win: 'Ctrl-]', mac: 'Command-]|Ctrl-]'},
        readOnly: true,
        exec() { return Backbone.Mediator.publish('level:scrub-forward', {}); }});
      addCommand({
        name: 'level-scrub-back',
        bindKey: {win: 'Ctrl-[', mac: 'Command-[|Ctrl-]'},
        readOnly: true,
        exec() { return Backbone.Mediator.publish('level:scrub-back', {}); }});
      addCommand({
        name: 'spell-step-forward',
        bindKey: {win: 'Ctrl-Alt-]', mac: 'Command-Alt-]|Ctrl-Alt-]'},
        readOnly: true,
        exec() { return Backbone.Mediator.publish('tome:spell-step-forward', {}); }});
      addCommand({
        name: 'spell-step-backward',
        bindKey: {win: 'Ctrl-Alt-[', mac: 'Command-Alt-[|Ctrl-Alt-]'},
        readOnly: true,
        exec() { return Backbone.Mediator.publish('tome:spell-step-backward', {}); }});
      addCommand({
        name: 'spell-beautify',
        bindKey: {win: 'Ctrl-Shift-B', mac: 'Command-Shift-B|Ctrl-Shift-B'},
        exec() { return Backbone.Mediator.publish('tome:spell-beautify', {}); }});
      addCommand({
        name: 'prevent-line-jump',
        bindKey: {win: 'Ctrl-L', mac: 'Command-L'},
        passEvent: true,
        exec() {}
      });  // just prevent default ACE go-to-line alert
      addCommand({
        name: 'open-fullscreen-editor',
        bindKey: {win: 'Ctrl-Shift-M', mac: 'Command-Shift-M|Ctrl-Shift-M'},
        exec() { return Backbone.Mediator.publish('tome:toggle-maximize', {}); }});
      addCommand({
        // TODO: Restrict to beginner campaign levels like we do backspaceThrottle
        name: 'enter-skip-delimiters',
        bindKey: 'Enter|Return',
        exec: () => {
          if (this.aceSession.selection.isEmpty()) {
            let delimMatch;
            const cursor = this.ace.getCursorPosition();
            const line = this.aceDoc.getLine(cursor.row);
            if (delimMatch = line.substring(cursor.column).match(/^(["|']?\)+;?)/)) {
              const newRange = this.ace.getSelectionRange();
              newRange.setStart(newRange.start.row, newRange.start.column + delimMatch[1].length);
              newRange.setEnd(newRange.end.row, newRange.end.column + delimMatch[1].length);
              this.aceSession.selection.setSelectionRange(newRange);
            }
          }
          return this.ace.execCommand('insertstring', '\n');
        }
      });
      addCommand({
        name: 'disable-spaces',
        bindKey: 'Space',
        exec: () => {
          let left;
          let disableSpaces = this.options.level.get('disableSpaces') || false;
          const aceConfig = (left = me.get('aceConfig')) != null ? left : {};
          if (aceConfig.keyBindings && (aceConfig.keyBindings !== 'default')) { disableSpaces = false; }  // Not in vim/emacs mode
          if (['lua', 'java', 'cpp', 'coffeescript', 'html'].includes(this.spell.language)) { disableSpaces = false; }  // Don't disable for more advanced/experimental languages
          if (!disableSpaces || (_.isNumber(disableSpaces) && (disableSpaces < me.level()))) {
            return this.ace.execCommand('insertstring', ' ');
          }
          const line = this.aceDoc.getLine(this.ace.getCursorPosition().row);
          if (this.singleLineCommentRegex().test(line)) { return this.ace.execCommand('insertstring', ' '); }
        }
      });

      if (this.options.level.get('backspaceThrottle')) {
        return addCommand({
          name: 'throttle-backspaces',
          bindKey: 'Backspace',
          exec: () => {
            // Throttle the backspace speed
            // Slow to 500ms when whitespace at beginning of line is first encountered
            // Slow to 100ms for remaining whitespace at beginning of line
            // Rough testing showed backspaces happen at 150ms when tapping.
            // Backspace speed varies by system when holding, 30ms on fastest Macbook setting.
            const nowDate = Date.now();
            if (this.aceSession.selection.isEmpty()) {
              const cursor = this.ace.getCursorPosition();
              const line = this.aceDoc.getLine(cursor.row);
              if (/^\s*$/.test(line.substring(0, cursor.column))) {
                if (this.backspaceThrottleMs == null) { this.backspaceThrottleMs = 500; }
                // console.log "SpellView @backspaceThrottleMs=#{@backspaceThrottleMs}"
                // console.log 'SpellView lastBackspace diff', nowDate - @lastBackspace if @lastBackspace?
                if ((this.lastBackspace == null) || ((nowDate - this.lastBackspace) > this.backspaceThrottleMs)) {
                  this.backspaceThrottleMs = 100;
                  this.lastBackspace = nowDate;
                  this.ace.remove("left");
                }
                return;
              }
            }
            this.backspaceThrottleMs = null;
            this.lastBackspace = nowDate;
            return this.ace.remove("left");
          }
        });
      }
    }


    hookACECustomBehavior() {
      let left;
      const aceConfig = (left = me.get('aceConfig')) != null ? left : {};
      this.ace.commands.on('exec', e => {
        // When pressing enter with an active selection, just make a new line under it.
        if (e.command.name === 'enter-skip-delimiters') {
          const selection = this.ace.selection.getRange();
          if ((selection.start.column !== selection.end.column) || (selection.start.row !== selection.end.row)) {
            e.editor.execCommand('gotolineend');
            return true;
          }
        }
      });

      // Add visual indent guides
      const {
        language
      } = this.spell;
      const ensureLineStartsBlock = function(line) {
        if (language !== "python") { return false; }
        const match = /^\s*([^#]+)/.exec(line);
        if ((match == null)) { return false; }
        return /:\s*$/.test(match[1]);
      };

      this.indentDivMarkers = [];

      return this.aceSession.addDynamicMarker({
        update: (_, markerLayer, session, config) => {
          let indentVisualMarker, left1;
          ({
            Range
          } = ace.require('ace/range'));

          const {
            foldWidgets
          } = this.aceSession;
          if ((foldWidgets == null)) { return; }

          const lines = this.aceDoc.getAllLines();
          const startOfRow = function(r) {
            const str = lines[r];
            const ar = str.match(/^\s*/);
            return ar.pop().length;
          };

          const colors = [{border: '74,144,226', fill: '108,162,226'}, {border: '132,180,235', fill: '230,237,245'}];

          this.indentDivMarkers.forEach(node => node.remove());
          this.indentDivMarkers = [];

          for (let row = 0, end = this.aceSession.getLength(), asc = 0 <= end; asc ? row <= end : row >= end; asc ? row++ : row--) {
            var docRange, start;
            if (foldWidgets[row] == null) { foldWidgets[row] = this.aceSession.getFoldWidget(row); }
            if ((foldWidgets == null) || (foldWidgets[row] !== "start")) { continue; }
            try {
              docRange = this.aceSession.getFoldWidgetRange(row);
            } catch (error) {
              console.warn(`Couldn't find fold widget docRange for row ${row}:`, error);
            }
            if ((docRange == null)) {
              var guess = startOfRow(row);
              docRange = new Range(row,guess,row,guess+4);
            }

            if (!ensureLineStartsBlock(lines[row])) { continue; }

            if (/^\s+$/.test(lines[docRange.end.row+1])) {
              docRange.end.row += 1;
            }

            var xstart = startOfRow(row);
            if (language === 'python') {
              var asc1, crow, end1;
              var requiredIndent = new RegExp('^' + new Array(Math.floor((xstart / 4) + 1)).join('(    |\t)') + '(    |\t)+(\\S|\\s*$)');
              for (start = docRange.start.row+1, crow = start, end1 = docRange.end.row, asc1 = start <= end1; asc1 ? crow <= end1 : crow >= end1; asc1 ? crow++ : crow--) {
                if (!requiredIndent.test(lines[crow])) {
                  docRange.end.row = crow - 1;
                  break;
                }
              }
            }

            var rstart = this.aceSession.documentToScreenPosition(docRange.start.row, docRange.start.column);
            var rend = this.aceSession.documentToScreenPosition(docRange.end.row, docRange.end.column);
            var range = new Range(rstart.row, rstart.column, rend.row, rend.column);
            var level = Math.floor(xstart / 4);
            var color = colors[level % colors.length];
            var bw = 3;
            var to = markerLayer.$getTop(range.start.row, config);
            var t = markerLayer.$getTop(range.start.row + 1, config);
            var h = config.lineHeight * (range.end.row - range.start.row);
            var l = markerLayer.$padding + (xstart * config.characterWidth);
            // w = (data.i - data.b) * config.characterWidth
            var w = 4 * config.characterWidth;
            var fw = config.characterWidth * ( this.aceSession.getScreenLastRowColumn(range.start.row) - xstart );

            var lineAbove = document.createElement("div");
            lineAbove.setAttribute("style", `\
position: absolute; top: ${to}px; left: ${l}px; width: ${fw+bw}px; height: ${config.lineHeight}px;
border: ${bw}px solid rgba(${color.border},1); border-left: none;\
`
            );

            var indentedBlock = document.createElement("div");
            indentedBlock.setAttribute("style", `\
position: absolute; top: ${t}px; left: ${l}px; width: ${w}px; height: ${h}px; background-color: rgba(${color.fill},0.5);
border-right: ${bw}px solid rgba(${color.border},1); border-bottom: ${bw}px solid rgba(${color.border},1);\
`
            );

            indentVisualMarker = document.createElement("div");
            indentVisualMarker.appendChild(lineAbove);
            indentVisualMarker.appendChild(indentedBlock);

            this.indentDivMarkers.push(indentVisualMarker);
          }

          markerLayer.elt("indent-highlight");
          const parentNode = (left1 = markerLayer.element.childNodes[markerLayer.i - 1]) != null ? left1 : markerLayer.element.lastChild;
          return (() => {
            const result = [];
            for (indentVisualMarker of Array.from(this.indentDivMarkers)) {               result.push(parentNode.appendChild(indentVisualMarker));
            }
            return result;
          })();
        }
      });
    }

    fillACE() {
      this.ace.setValue(this.spell.source);
      this.aceSession.setUndoManager(new UndoManager());
      this.ace.clearSelection();
      if (this.options.blocks) { return this.addBlockly(); }
    }

    onPaletteUpdated(e) {
      if (this.propertyEntryGroups) { return; }
      this.propertyEntryGroups = e.entryGroups;
      if (this.awaitingBlockly) {
        this.addBlockly();
        return this.awaitingBlockly = false;
      }
    }

    addBlockly() {
      if (!this.propertyEntryGroups) {
        this.awaitingBlockly = true;
        return;
      }
      const codeLanguage = this.spell.language;
      const toolbox = blocklyUtils.createBlocklyToolbox({ propertyEntryGroups: this.propertyEntryGroups, codeLanguage, level: this.options.level });
      blocklyUtils.registerBlocklyTheme();
      const targetDiv = this.$('#blockly-container');
      const blocklyOptions = blocklyUtils.createBlocklyOptions({ toolbox });
      this.blockly = Blockly.inject(targetDiv[0], blocklyOptions);
      this.blocklyActive = true;
      blocklyUtils.initializeBlocklyTooltips();

      const lastBlocklyState = this.session.fake ? null : storage.load(`lastBlocklyState_${this.options.level.get('original')}_${this.session.id}`);
      if (lastBlocklyState) {
        blocklyUtils.loadBlocklyState(lastBlocklyState, this.blockly);
        // Rerun the code
        this.blocklyToAce();
        for (var block of Array.from(this.blockly.getAllBlocks())) {
          // Make long comments not so long. (The full comments will be visible, wrapped, in text version anyway.)
          if (block.type === 'comment') {
            block.setCollapsed(true);
          }
        }
        this.recompile();
      }
      //else
      //  # Initialize Blockly from the text code
      //  @aceToBlockly true

      this.resizeBlockly();

      if (this.onCodeChangeMetaHandler) {
        return this.blockly.addChangeListener(this.blocklyToAce);
      }
    }

    getBlocklySource() {
      return blocklyUtils.getBlocklySource(this.blockly, this.spell.language);
    }

    blocklyToAce() {
      if (this.eventsSuppressed) { return; }
      if (!this.blockly) { return; }
      const { blocklyState, blocklySource, combined } = this.getBlocklySource();
      const aceSource = this.getSource();

      // For debugging, including Blockly JSON serialization
      //return if combined is aceSource
      //console.log 'B2A: Changing ace source from', aceSource, 'to', combined
      //@updateACEText combined

      // Just the code
      if (blocklySource === aceSource) { return; }
      console.log('B2A: Changing ace source from', aceSource, 'to', blocklySource, 'with state', blocklyState);
      this.updateACEText(blocklySource);

      if (!this.session.fake) {
        return storage.save(`lastBlocklyState_${this.options.level.get('original')}_${this.session.id}`, blocklyState);
      }
    }

    aceToBlockly(force) {
      let aceSource;
      if (this.eventsSuppressed && !force) { return; }
      if (!this.blockly) { return; }
      // TODO: this is currently not doing anything until we update it with code -> blockly generation
      return;
      const aceCombined = this.ace.getValue();
      const match = aceCombined.match(/^[#\/\-]+BLOCKLY. ([^\n]*)\n\n(.*)/);  // TODO: check if this can do multiline or use something else
      if (match != null) {
        const aceState = match[1];
        aceSource = match[2];
      }
      const { blocklyState, blocklySource, combined } = this.getBlocklySource();
      if ((aceSource == null) || (aceSource === blocklySource)) { return; }
      console.log('A2B: Changing blockly source from', blocklySource, 'to', aceSource);
      this.eventsSuppressed = true;
      //console.log 'would set to', blocklyState
      Blockly.serialization.workspaces.load(blocklyState, this.blockly);
      //@resizeBlockly()  # Needed?
      return this.eventsSuppressed = false;
    }

    lockDefaultCode(force) {
      // TODO: Lock default indent for an empty line?
      let left;
      if (force == null) { force = false; }
      const lockDefaultCode = this.options.level.get('lockDefaultCode') || false;
      if (!lockDefaultCode || (_.isNumber(lockDefaultCode) && (lockDefaultCode < me.level()))) {
        return;
      }
      if ((this.spell.source !== this.spell.originalSource) && !force) { return; }
      if (this.isIE()) { return; }  // Temporary workaround for #2512
      const aceConfig = (left = me.get('aceConfig')) != null ? left : {};
      if (aceConfig.keyBindings && (aceConfig.keyBindings !== 'default')) { return; }  // Don't lock in vim/emacs mode

      console.info('Locking down default code.');

      const intersects = () => {
        for (var range of Array.from(this.readOnlyRanges)) { if (this.ace.getSelectionRange().intersects(range)) { return true; } }
        return false;
      };

      const intersectsLeft = () => {
        const leftRange = this.ace.getSelectionRange().clone();
        if (leftRange.start.column > 0) {
          leftRange.setStart(leftRange.start.row, leftRange.start.column - 1);
        } else if (leftRange.start.row > 0) {
          leftRange.setStart(leftRange.start.row - 1, 0);
        }
        for (var range of Array.from(this.readOnlyRanges)) { if (leftRange.intersects(range)) { return true; } }
        return false;
      };

      const intersectsRight = () => {
        const rightRange = this.ace.getSelectionRange().clone();
        if (rightRange.end.column < this.aceDoc.getLine(rightRange.end.row).length) {
          rightRange.setEnd(rightRange.end.row, rightRange.end.column + 1);
        } else if (rightRange.start.row < (this.aceDoc.getLength() - 1)) {
          rightRange.setEnd(rightRange.end.row + 1, 0);
        }
        for (var range of Array.from(this.readOnlyRanges)) { if (rightRange.intersects(range)) { return true; } }
        return false;
      };

      // TODO: Performance: Consider removing, may be dead code.
      const pulseLockedCode = () => $('.locked-code').finish().addClass('pulsating').effect('shake', {times: 1, distance: 2, direction: 'down'}).removeClass('pulsating');

      // TODO: Performance: Consider removing, may be dead code.
      const preventReadonly = function(next) {
        if (intersects()) {
          pulseLockedCode();
          return true;
        }
        return (typeof next === 'function' ? next() : undefined);
      };

      const interceptCommand = function(obj, method, wrapper) {
        const orig = obj[method];
        obj[method] = function() {
          const args = Array.prototype.slice.call(arguments);
          return wrapper(() => orig.apply(obj, args));
        };
        return obj[method];
      };

      const finishRange = (row, startRow, startColumn) => {
        const range = new Range(startRow, startColumn, row, this.aceSession.getLine(row).length - 1);
        range.start = this.aceDoc.createAnchor(range.start);
        range.end = this.aceDoc.createAnchor(range.end);
        range.end.$insertRight = true;
        return this.readOnlyRanges.push(range);
      };

      // Remove previous locked code highlighting
      if (this.lockedCodeMarkerIDs != null) {
        for (var marker of Array.from(this.lockedCodeMarkerIDs)) { this.aceSession.removeMarker(marker); }
      }
      this.lockedCodeMarkerIDs = [];

      // Create locked default code text ranges
      this.readOnlyRanges = [];
      if (['python', 'coffeescript'].includes(this.spell.language)) {
        // Lock contiguous section of default code
        // Only works for languages without closing delimeters on blocks currently
        let lastRow;
        const lines = this.aceDoc.getAllLines();
        for (let row = 0; row < lines.length; row++) {
          var line = lines[row];
          if (!/^\s*$/.test(line)) {
            lastRow = row;
          }
        }
        if (lastRow != null) {
          this.readOnlyRanges.push(new Range(0, 0, lastRow, lines[lastRow].length - 1));
        }
      }

      // TODO: Highlighting does not work for multiple ranges
      // TODO: Everything looks correct except the actual result.
      // TODO: https://github.com/codecombat/codecombat/issues/1852
      // else
      //   # Create a read-only range for each chunk of text not separated by an empty line
      //   startRow = startColumn = null
      //   for row in [0...@aceSession.getLength()]
      //     unless /^\s*$/.test @aceSession.getLine(row)
      //       unless startRow? and startColumn?
      //         startRow = row
      //         startColumn = 0
      //     else
      //       if startRow? and startColumn?
      //         finishRange row - 1, startRow, startColumn
      //         startRow = startColumn = null
      //   if startRow? and startColumn?
      //     finishRange @aceSession.getLength() - 1, startRow, startColumn

      // Highlight locked ranges
      for (var range of Array.from(this.readOnlyRanges)) {
        this.lockedCodeMarkerIDs.push(this.aceSession.addMarker(range, 'locked-code', 'fullLine'));
      }

      // Override write operations that intersect with default code
      interceptCommand(this.ace, 'onPaste', preventReadonly);
      interceptCommand(this.ace, 'onCut', preventReadonly);
      // TODO: can we use interceptCommand for this too?  'exec' and 'onExec' did not work.
      return this.ace.commands.on('exec', e => {
        e.stopPropagation();
        e.preventDefault();
        if (((e.command.name === 'insertstring') && intersects()) ||
           (['Backspace', 'throttle-backspaces'].includes(e.command.name) && intersectsLeft()) ||
           ((e.command.name === 'del') && intersectsRight())) {
          __guardMethod__(this.autocomplete, 'off', o => o.off());
          pulseLockedCode(); // TODO: Performance: Consider removing, may be dead code.
          return false;
        } else if (['enter-skip-delimiters', 'Enter', 'Return'].includes(e.command.name)) {
          if (intersects()) {
            e.editor.navigateDown(1);
            e.editor.navigateLineStart();
            return false;
          } else if (['Enter', 'Return'].includes(e.command.name) && !__guard__(__guard__(e.editor != null ? e.editor.completer : undefined, x1 => x1.popup), x => x.isOpen)) {
            __guardMethod__(this.autocomplete, 'on', o1 => o1.on());
            return e.editor.execCommand('enter-skip-delimiters');
          }
        }
        __guardMethod__(this.autocomplete, 'on', o2 => o2.on());
        return e.command.exec(e.editor, e.args || {});
    });
    }

    initAutocomplete(autocompleteOn) {
      // TODO: Turn on more autocompletion based on level sophistication
      // TODO: E.g. using the language default snippets yields a bunch of crazy non-beginner suggestions
      // TODO: Options logic shouldn't exist both here and in updateAutocomplete()
      let left;
      this.autocompleteOn = autocompleteOn;
      if (this.spell.language === 'html') { return; }
      const popupFontSizePx = (left = this.options.level.get('autocompleteFontSizePx')) != null ? left : 16;
      return this.autocomplete = new Autocomplete(this.ace, {
        basic: false,
        liveCompletion: false,
        snippetsLangDefaults: false,
        completers: {
          keywords: false,
          snippets: this.autocompleteOn
        },
        autoLineEndings: {
          javascript: ';',
          java: ';',
          c_cpp: ';'
        }, // Match ace editor language mode
        popupFontSizePx,
        popupLineHeightPx: 1.5 * popupFontSizePx,
        popupWidthPx: 380
      }
      );
    }

    updateAutocomplete(autocompleteOn) {
      this.autocompleteOn = autocompleteOn;
      return (this.autocomplete != null ? this.autocomplete.set('snippets', this.autocompleteOn) : undefined);
    }

    reallyAddUserSnippets(source, lang, session) {
      if (!this.autocomplete || !this.autocompleteOn) { return; }
      const newIdentifiers = aceUtils.parseUserSnippets(source, lang, session);
      // console.log 'debug newIdentifiers: ', newIdentifiers
      if (this.editorLang != null) { return (this.autocomplete != null ? this.autocomplete.addCustomSnippets(Object.values(newIdentifiers), this.editorLang) : undefined); }
    }

    addAutocompleteSnippets(e) {
      // Snippet entry format:
      // content: code inserted into document
      // meta: displayed right-justfied in popup
      // name: displayed left-justified in popup, and what's being matched
      // tabTrigger: fallback for name field
      if (!this.autocomplete || !this.autocompleteOn) { return; }
      return this.autocomplete.addCodeCombatSnippets(this.options.level, this, e);
    }

    translateFindNearest() {
      // If they have advanced glasses but are playing a level which assumes earlier glasses, we'll adjust the sample code to use the more advanced APIs instead.
      const oldSource = this.getSource();
      let newSource = oldSource.replace(/(self:|self.|this.|@)findNearestEnemy\(\)/g, "$1findNearest($1findEnemies())");
      newSource = newSource.replace(/(self:|self.|this.|@)findNearestItem\(\)/g, "$1findNearest($1findItems())");
      if (oldSource === newSource) { return; }
      this.spell.originalSource = newSource;
      this.updateACEText(newSource);
      return _.delay((() => (typeof this.recompile === 'function' ? this.recompile() : undefined)), 1000);
    }

    createFirepad() {
      // Currently not called; could be brought back for future multiplayer modes.
      // Load from firebase or the original source if there's nothing there.
      if (this.firepadLoading) { return; }
      this.eventsSuppressed = true;
      this.loaded = false;
      this.previousSource = this.ace.getValue();
      this.ace.setValue('');
      this.aceSession.setUndoManager(new UndoManager());
      const fireURL = 'https://codecombat.firebaseio.com/' + this.spell.pathComponents.join('/');
      this.fireRef = new Firebase(fireURL);
      const firepadOptions = {userId: me.id};
      this.firepad = Firepad.fromACE(this.fireRef, this.ace, firepadOptions);
      this.firepadLoading = true;
      return this.firepad.on('ready', () => {
        if (this.destroyed) { return; }
        this.firepadLoading = false;
        const firepadSource = this.ace.getValue();
        if (firepadSource) {
          this.spell.source = firepadSource;
        } else {
          this.ace.setValue(this.previousSource);
          this.aceSession.setUndoManager(new UndoManager());
          this.ace.clearSelection();
        }
        return this.onAllLoaded();
      });
    }

    onAllLoaded() {
      return this.fetchToken(this.spell.source, this.spell.language).then(token => {
        this.spell.transpile(token);
        this.spell.loaded = true;
        Backbone.Mediator.publish('tome:spell-loaded', {spell: this.spell});
        this.eventsSuppressed = false;  // Now that the initial change is in, we can start running any changed code
        this.createToolbarView();
        if (this.options.level.isType('web-dev')) { return this.updateHTML({create: true}); }
      });
    }

    createDebugView() {
      if (this.options.level.isType('hero', 'hero-ladder', 'hero-coop', 'course', 'course-ladder', 'game-dev', 'web-dev', 'ladder')) { return; }  // We'll turn this on later, maybe, but not yet.
      this.debugView = new SpellDebugView({ace: this.ace, thang: this.thang, spell:this.spell});
      return this.$el.append(this.debugView.render().$el.hide());
    }

    createTranslationView() {
      this.translationView = new SpellTranslationView({ ace: this.ace, supermodel: this.supermodel });
      return this.$el.append(this.translationView.render().$el.hide());
    }

    createToolbarView() {
      this.toolbarView = new SpellToolbarView({ace: this.ace});
      return this.$el.append(this.toolbarView.render().$el);
    }

    onMouseOut(e) {
      return (this.debugView != null ? this.debugView.onMouseOut(e) : undefined);
    }

    onContactButtonPressed(e) {
      return this.saveSpade();
    }

    getSource() {
      return this.ace.getValue();
    }

    setThang(thang) {
      this.focus();
      this.lastScreenLineCount = null;
      this.updateLines();
      if (thang.id === (this.thang != null ? this.thang.id : undefined)) { return; }
      this.thang = thang;
      this.spellThang = this.spell.thang;
      if (!this.debugView) { this.createDebugView(); }
      if (this.debugView != null) {
        this.debugView.thang = this.thang;
      }
      if (!this.translationView) { this.createTranslationView(); }
      if (this.toolbarView != null) {
        this.toolbarView.toggleFlow(false);
      }
      this.updateAether(false, false);
      // @addAutocompleteSnippets()
      return this.highlightCurrentLine();
    }

    cast(preload, realTime, justBegin, cinematic) {
      if (preload == null) { preload = false; }
      if (realTime == null) { realTime = false; }
      if (justBegin == null) { justBegin = false; }
      if (cinematic == null) { cinematic = false; }
      return Backbone.Mediator.publish('tome:cast-spell', { spell: this.spell, thang: this.thang, preload, realTime, justBegin, cinematic });
    }

    notifySpellChanged() {
      if (this.destroyed) { return; }
      return Backbone.Mediator.publish('tome:spell-changed', {spell: this.spell});
    }

    notifyEditingEnded() {
      if (this.destroyed || (this.aceDoc != null ? this.aceDoc.undergoingFirepadOperation : undefined)) { return; }  // from my Firepad ACE adapter
      return Backbone.Mediator.publish('tome:editing-ended', {});
    }

    notifyEditingBegan() {
      if (this.destroyed || (this.aceDoc != null ? this.aceDoc.undergoingFirepadOperation : undefined)) { return; }  // from my Firepad ACE adapter
      return Backbone.Mediator.publish('tome:editing-began', {});
    }

    updateSolutionLines(screenLineCount, ace, aceCls, areaId) {
      // wrap the updateAceLine to avoid throttle mess up different params(aceCls)
      return this.updateAceLines(screenLineCount, ace, aceCls, areaId);
    }

    updateAceLines(screenLineCount, ace, aceCls, areaId) {
      let spellPaletteHeight;
      if (ace == null) { ({
        ace
      } = this); }
      if (aceCls == null) { aceCls = '.ace'; }
      if (areaId == null) { areaId = '#code-area'; }
      const lineHeight = ace.renderer.lineHeight || 20;
      const spellPaletteView = $('#tome-view #spell-palette-view-bot');
      const spellTopBarHeight = $('#spell-top-bar-view').outerHeight();
      if (aceCls === '.ace') {
        spellPaletteHeight = spellPaletteView.outerHeight();
      } else {
        spellPaletteHeight = 0;
      }
      const windowHeight = $(window).innerHeight();
      const spellPaletteAllowedHeight = Math.min(spellPaletteHeight, windowHeight / 2);
      const topOffset = $(aceCls).offset().top;
      const gameHeight = $('#game-area').innerHeight();
      const heightScale = aceCls === '.ace' ? 1 : 0.5;

      // If the spell palette is too tall, we'll need to shrink it.
      const maxHeightOffset = 75;
      const minHeightOffset = 175;
      const maxHeight = Math.min(windowHeight, Math.max(windowHeight, 600)) - topOffset - spellPaletteAllowedHeight - maxHeightOffset;
      const minHeight = Math.min(maxHeight * heightScale, Math.min(gameHeight, Math.max(windowHeight, 600)) - spellPaletteHeight - minHeightOffset);

      const spellPalettePosition = spellPaletteHeight > 0 ? 'bot' : 'mid';
      const minLinesBuffer = spellPalettePosition === 'bot' ? 0 : 2;
      const linesAtMinHeight = Math.max(8, Math.floor((minHeight / lineHeight) - minLinesBuffer));
      const linesAtMaxHeight = Math.floor(maxHeight / lineHeight);
      let lines = Math.max(linesAtMinHeight, Math.min(screenLineCount + 2, linesAtMaxHeight), 8);
      if (_.isNaN(lines)) { lines = 8; }

      ace.setOptions({minLines: lines, maxLines: lines});

      // If bot: move spell palette up, slightly overlapping us.
      const newTop = 185 + (lineHeight * lines);
      if (aceCls === '.ace') {
        spellPaletteView.css('top', newTop);

        const codeAreaBottom = spellPaletteHeight ? windowHeight - (newTop + spellPaletteHeight + 20) : 0;
        return $(areaId).css('bottom', codeAreaBottom);
      }
    }
      //console.log { lineHeight, spellTopBarHeight, spellPaletteHeight, spellPaletteAllowedHeight, windowHeight, topOffset, gameHeight, minHeight, maxHeight, linesAtMinHeight, linesAtMaxHeight, lines, newTop, screenLineCount }

    updateLines() {
      // Make sure there are always blank lines for the player to type on, and that the editor resizes to the height of the lines.
      if (this.destroyed) { return; }
      let lineCount = this.aceDoc.getLength();
      const lastLine = this.aceDoc.$lines[lineCount - 1];
      if (/\S/.test(lastLine)) {
        const cursorPosition = this.ace.getCursorPosition();
        const wasAtEnd = (cursorPosition.row === (lineCount - 1)) && (cursorPosition.column === lastLine.length);
        this.aceDoc.insertNewLine({row: lineCount, column: 0});  //lastLine.length
        if (wasAtEnd) { this.ace.navigateLeft(1); }
        ++lineCount;
        // Force the popup back
        __guard__(this.ace != null ? this.ace.completer : undefined, x => x.showPopup(this.ace));
      }

      const screenLineCount = this.aceSession.getScreenLength();
      if (screenLineCount !== this.lastScreenLineCount) {
        this.lastScreenLineCount = screenLineCount;
        this.updateAceLines(screenLineCount);
      }

      if ((this.firstEntryToScrollLine != null) && __guard__(__guard__(this.ace != null ? this.ace.renderer : undefined, x2 => x2.$cursorLayer), x1 => x1.config)) {
        this.ace.scrollToLine(this.firstEntryToScrollLine, true, true);
        return this.firstEntryToScrollLine = undefined;
      }
    }

    hideProblemAlert() {
      if (this.destroyed) { return; }
      return Backbone.Mediator.publish('tome:hide-problem-alert', {});
    }

    saveSpade() {
      if (this.destroyed || !this.spade) { return; }
      this.spade.createUIEvent("saving-spade");
      const spadeEvents = this.spade.compile();
      const condensedEvents = this.spade.condense(spadeEvents);
      // Uncomment the below lines for a debug panel to display inside the level
      // uncondensedEvents = @spade.expand(condensedEvents)
      // @spade.debugPlay(uncondensedEvents)

      if (!condensedEvents.length) { return; }
      const compressedEvents = LZString.compressToUTF16(JSON.stringify(condensedEvents));
      const codeLog = new CodeLog({
        sessionID: this.options.session.id,
        level: {
          original: this.options.level.get('original'),
          majorVersion: (this.options.level.get('version')).major
        },
        levelSlug: this.options.level.get('slug'),
        userID: this.options.session.get('creator'),
        log: compressedEvents
      });

      return codeLog.save();
    }

    onShowVictory(e) {
      if (this.spade != null) {
        this.spade.createUIEvent("victory-shown");
      }
      if (this.saveSpadeTimeout != null) {
        window.clearTimeout(this.saveSpadeTimeout);
        this.saveSpadeTimeout = null;
        if (this.options.level.get('releasePhase') === 'beta') {
          return this.saveSpade();
        } else if ((Math.random() < 0.05) && _.find(utils.freeAccessLevels, {access: 'short', slug: this.options.level.get('slug')})) {
          return this.saveSpade();
        }
      }
    }

    onManualCast(e) {
      if (this.spade != null) {
        this.spade.createUIEvent("code-run");
      }
      const cast = this.$el.parent().length;
      this.recompile(cast, e.realTime, false);
      if (cast) { this.focus(); }
      if (this.options.level.isType('web-dev')) {
        this.sourceAtLastCast = this.getSource();
        this.ace.setStyle('spell-cast');
        return this.updateHTML({create: true});
      }
    }

    reloadCode(cast) {
      if (cast == null) { cast = true; }
      if (cast) { this.spell.reloadCode(); }
      this.thang = this.spell.thang.thang;
      this.updateACEText(this.spell.originalSource);
      this.lockDefaultCode(true);
      this.recompile(cast);
      Backbone.Mediator.publish('tome:spell-loaded', {spell: this.spell});
      this.hasSetInitialCursor = false;
      this.highlightCurrentLine();
      this.updateLines();
      if (this.spade != null) {
        return this.spade.createUIEvent("code-reset");
      }
    }

    recompile(cast, realTime, cinematic) {
      if (cast == null) { cast = true; }
      if (realTime == null) { realTime = false; }
      if (cinematic == null) { cinematic = false; }
      return this.fetchTokenForSource().then(source => {
        const readableSource = Aether.getTokenSource(source);
        const hasChanged = this.spell.source !== readableSource;
        if (hasChanged) {
          this.spell.transpile(source);
          this.updateAether(true, false);
        }
        if (cast) {  //and (hasChanged or realTime)  # just always cast now
          this.cast(false, realTime, false, cinematic);
        }
        if (hasChanged) {
          return this.notifySpellChanged();
        }
      });
    }

    updateACEText(source) {
      this.eventsSuppressed = true;
      if (this.firepad) {
        this.firepad.setText(source);
      } else {
        this.ace.setValue(source);
        this.ace.clearSelection();
        this.aceSession.setUndoManager(new UndoManager());
      }
      this.eventsSuppressed = false;
      try {
        return this.ace.resize(true);  // hack: @ace may not have updated its text properly, so we force it to refresh
      } catch (error) {
        return console.warn('Error resizing ACE after an update:', error);
      }
    }

    createOnCodeChangeHandlers() {
      if (this.onCodeChangeMetaHandler) { this.aceDoc.removeListener('change', this.onCodeChangeMetaHandler); }
      const onSignificantChange = [];
      const onAnyChange = [
        _.debounce(this.updateAether, this.options.level.isType('game-dev') ? 10 : 500),
        _.debounce(this.notifyEditingEnded, 1000),
        _.throttle(this.notifyEditingBegan, 250),
        _.throttle(this.notifySpellChanged, 300),
        _.throttle(this.updateLines, 500),
        _.throttle(this.hideProblemAlert, 500),
        _.throttle(this.aceToBlockly, 500)
      ];
      if (this.options.level.get('requiredCode')) { onSignificantChange.push(_.debounce(this.checkRequiredCode, 750)); }
      if (this.options.level.get('suspectCode')) { onSignificantChange.push(_.debounce(this.checkSuspectCode, 750)); }
      if (this.options.level.isType('web-dev')) { onAnyChange.push(_.throttle(this.updateHTML, 10)); }

      this.onCodeChangeMetaHandler = () => {
        if (this.eventsSuppressed) { return; }
        //@playSound 'code-change', volume: 0.5  # Currently not using this sound.
        if (this.spellThang) {
          return this.spell.hasChangedSignificantly(this.getSource(), this.spellThang.aether.raw, hasChanged => {
            let callback;
            if (!this.spellThang || hasChanged) {
              for (callback of Array.from(onSignificantChange)) { callback(); }  // Do these first
            }
            return (() => {
              const result = [];
              for (callback of Array.from(onAnyChange)) {                 result.push(callback());
              }
              return result;
            })();
          });  // Then these
        }
      };
      this.aceDoc.on('change', this.onCodeChangeMetaHandler);

      if (this.blockly) {
        return this.blockly.addChangeListener(this.blocklyToAce);
      }
    }

    onCursorActivity() {}  // Used to refresh autocast delay; doesn't do anything at the moment.

    updateHTML(options) {
      // TODO: Merge with onSpellChanged
      // NOTE: Consider what goes in onManualCast only
      if (options == null) { options = {}; }
      if (this.spell.hasChanged(this.spell.getSource(), this.sourceAtLastCast)) {
        this.ace.unsetStyle('spell-cast'); // NOTE: Doesn't do anything for web-dev as of this writing, including for consistency
      }
      this.clearWebDevErrors();
      return Backbone.Mediator.publish('tome:html-updated', {html: this.spell.constructHTML(this.getSource()), create: Boolean(options.create)});
    }

    // Design for a simpler system?
    // * Keep Aether linting, debounced, on any significant change
    // - All problems just vanish when you make any change to the code
    // * You wouldn't accept any Aether updates/runtime information/errors unless its code was current when you got it
    // * Store the last run Aether in each spellThang and use it whenever its code actually is current.
    //   Use dynamic markers for problem ranges and keep annotations/alerts in when insignificant
    //   changes happen, but always treat any change in the (trimmed) number of lines as a significant change.
    // - All problems have a master representation as a Problem, and we can easily generate all Problems from
    //   any Aether instance. Then when we switch contexts in any way, we clear, recreate, and reapply the Problems.
    // * Problem alerts have their own templated ProblemAlertViews.
    // * We'll only show the first problem alert, and it will always be at the bottom.
    //   Annotations and problem ranges can show all, I guess.
    // * The editor will reserve space for one annotation as a codeless area.
    // - Problem alerts and ranges will only show on fully cast worlds. Annotations will show continually.

    fetchToken(source, language) {
      if (!['java', 'cpp'].includes(language)) {
        return Promise.resolve(source);
      } else if (source in this.loadedToken) {
        return Promise.resolve(this.loadedToken[source]);
      }

      const headers =  { 'Accept': 'application/json', 'Content-Type': 'application/json' };
      const m = document.cookie.match(/JWT=([a-zA-Z0-9.]+)/);
      const service = __guard__(typeof window !== 'undefined' && window !== null ? window.localStorage : undefined, x => x.kodeKeeperService) || "https://asm14w94nk.execute-api.us-east-1.amazonaws.com/service/parse-code-kodekeeper";
      return fetch(service, {method: 'POST', mode:'cors', headers, body:JSON.stringify({code: source, language})})
      .then(x => x.json())
      .then(x => {
        this.loadedToken = {}; // only cache 1 source
        this.loadedToken[source] = x.token;
        return x.token;
      });
    }

    fetchTokenForSource() {
      const source = this.ace.getValue();
      return this.fetchToken(source, this.spell.language);
    }

    updateAether(force, fromCodeChange) {
      // Depending on whether we have any code changes, significant code changes, or have switched
      // to a new spellThang, we may want to refresh our Aether display.
      let aether;
      if (force == null) { force = false; }
      if (fromCodeChange == null) { fromCodeChange = true; }
      if (!(aether = this.spellThang != null ? this.spellThang.aether : undefined)) { return; }
      return this.fetchTokenForSource().then(source => {
        const readableSource = Aether.getTokenSource(source);
        return this.spell.hasChangedSignificantly(source, aether.raw, hasChanged => {
          const codeHasChangedSignificantly = force || hasChanged;
          const needsUpdate = codeHasChangedSignificantly || (this.spellThang !== this.lastUpdatedAetherSpellThang);
          if (!needsUpdate && (aether === this.displayedAether)) { return; }
          const {
            castAether
          } = this.spellThang;
          const codeIsAsCast = castAether && (readableSource === castAether.raw);
          if (codeIsAsCast) { aether = castAether; }
          if (!needsUpdate && (aether === this.displayedAether)) { return; }

          // Now that that's figured out, perform the update.
          // The web worker Aether won't track state, so don't have to worry about updating it
          const finishUpdatingAether = aether => {
            this.clearAetherDisplay(); // In case problems were added since last clearing
            this.displayAether(aether, codeIsAsCast);
            this.lastUpdatedAetherSpellThang = this.spellThang;
            if (fromCodeChange) { return this.guessWhetherFinished(aether); }
          };

          this.clearAetherDisplay();
          if (codeHasChangedSignificantly && !codeIsAsCast) {
            if (this.worker) {
              const workerMessage = {
                function: 'transpile',
                spellKey: this.spell.spellKey,
                source
              };

              this.worker.addEventListener('message', function(e) {
                const workerData = JSON.parse(e.data);
                if ((workerData.function === 'transpile') && (workerData.spellKey === this.spell.spellKey)) {
                  this.worker.removeEventListener('message', arguments.callee, false);
                  aether.problems = workerData.problems;
                  aether.raw = readableSource;
                  return finishUpdatingAether(aether);
                }
              }.bind(this));
              return this.worker.postMessage(JSON.stringify(workerMessage));
            } else {
              aether.transpile(source);
              return finishUpdatingAether(aether);
            }
          } else {
            return finishUpdatingAether(aether);
          }
        });
      });
    }

    // Each problem-generating piece (aether, web-dev, ace html worker) clears its own problems/annotations
    clearAetherDisplay() {
      this.clearProblemsCreatedBy('aether');
      return this.highlightCurrentLine({});  // This'll remove all highlights
    }

    clearWebDevErrors() {
      return this.clearProblemsCreatedBy('web-dev-iframe');
    }

    clearProblemsCreatedBy(createdBy) {
      if (this.aceSession != null) {
        const nonAetherAnnotations = _.reject(this.aceSession.getAnnotations(), annotation => annotation.createdBy === createdBy);
        this.reallySetAnnotations(nonAetherAnnotations);
      }

      const problemsToClear = _.filter(this.problems, p => p.createdBy === createdBy);
      problemsToClear.forEach(problem => problem.destroy());
      this.problems = _.difference(this.problems, problemsToClear);
      return Backbone.Mediator.publish('tome:problems-updated', {spell: this.spell, problems: this.problems, isCast: false});
    }

    convertAetherProblems(aether, aetherProblems, isCast) {
      // TODO: Functional-ify
      return _.unique(aetherProblems, p => p.userInfo != null ? p.userInfo.key : undefined).map(aetherProblem => {
        return new Problem({ aether, aetherProblem, ace: this.ace, isCast, levelID: this.options.levelID });
    });
    }

    displayAether(aether, isCast) {
      let problem;
      if (isCast == null) { isCast = false; }
      this.displayedAether = aether;
      if (this.ace == null) { return; }
      isCast = isCast || !_.isEmpty(aether.metrics) || _.some(aether.getAllProblems(), {type: 'runtime'});
      const annotations = this.aceSession.getAnnotations();

      const newProblems = this.convertAetherProblems(aether, aether.getAllProblems(), isCast);
      for (problem of Array.from(newProblems)) { if (problem.annotation) { annotations.push(problem.annotation); } }
      if (isCast) {
        if (newProblems[0]) { this.displayProblemBanner(newProblems[0]); }
        for (problem of Array.from(newProblems)) { this.saveUserCodeProblem(aether, problem.aetherProblem); }
      }
      this.problems = this.problems.concat(newProblems);

      this.aceSession.setAnnotations(annotations);
      if (!_.isEmpty(aether.flow)) { this.highlightCurrentLine(aether.flow); }
      //console.log '  and we could do the metrics', aether.metrics unless _.isEmpty aether.metrics
      //console.log '  and we could do the style', aether.style unless _.isEmpty aether.style
      //console.log '  and we could do the visualization', aether.visualization unless _.isEmpty aether.visualization
      Backbone.Mediator.publish('tome:problems-updated', {spell: this.spell, problems: this.problems, isCast});
      return this.ace.resize();
    }

    // Tell ProblemAlertView to display this problem (only)
    displayProblemBanner(problem) {
      if (this.spade != null) {
        this.spade.createUIEvent("code-error");
      }
      let lineOffsetPx = 0;
      if (problem.row != null) {
        for (let i = 0, end = problem.row, asc = 0 <= end; asc ? i < end : i > end; asc ? i++ : i--) {
          lineOffsetPx += this.aceSession.getRowLength(i) * this.ace.renderer.lineHeight;
        }
        lineOffsetPx -= this.ace.session.getScrollTop();
      }
      if (!['info', 'warning'].includes(problem.level)) {
        Backbone.Mediator.publish('playback:stop-cinematic-playback', {});
      }
        // TODO: find a way to also show problem alert if it's compile-time, and/or not enter cinematic mode at all
      return Backbone.Mediator.publish('tome:show-problem-alert', {problem, lineOffsetPx: Math.max(lineOffsetPx, 0)});
    }

    // Gets the number of lines before the start of <script> content in the usercode
    // Because Errors report their line number relative to the <script> tag
    linesBeforeScript(html) {
      // TODO: refactor, make it work with multiple scripts. What to do when error is in level-creator's code?
      return _.size(html.split('<script>')[0].match(/\n/g));
    }

    addAnnotation(annotation) {
      const annotations = this.aceSession.getAnnotations();
      annotations.push(annotation);
      return this.reallySetAnnotations(annotations);
    }

    // Handle errors from the web-dev iframe asynchronously
    onWebDevError(error) {
      // TODO: Refactor this and the Aether problem flow to share as much as possible.
      // TODO: Handle when the error is in our code, not theirs
      // Compensate for line number being relative to <script> tag
      const offsetError = _.merge({}, error, { line: error.line + this.linesBeforeScript(this.getSource()) });
      const userCodeHasChangedSinceLastCast = this.spell.hasChanged(this.spell.getSource(), this.sourceAtLastCast);
      const problem = new Problem({ error: offsetError, ace: this.ace, levelID: this.options.levelID, userCodeHasChangedSinceLastCast });
      // Ignore the Problem if we already know about it
      if (_.any(this.problems, preexistingProblem => problem.isEqual(preexistingProblem))) {
        return problem.destroy();
      } else { // Ok, the problem is worth keeping
        this.problems.push(problem);
        this.displayProblemBanner(problem);

        // @saveUserCodeProblem(aether, aetherProblem) # TODO: Enable saving of web-dev user code problems
        if (problem.annotation) { this.addAnnotation(problem.annotation); }
        return Backbone.Mediator.publish('tome:problems-updated', {spell: this.spell, problems: this.problems, isCast: false});
      }
    }

    onProblemsUpdated({ spell, problems, isCast }) {
      // This just handles some ace styles for now; other things handle @problems changes elsewhere
      if (this.ace != null) {
        this.ace[problems.length ? 'setStyle' : 'unsetStyle']('user-code-problem');
        return this.ace[isCast ? 'setStyle' : 'unsetStyle']('spell-cast'); // Does this still do anything?
      }
    }

    saveUserCodeProblem(aether, aetherProblem) {
      // Skip duplicate problems
      const hashValue = aether.raw + aetherProblem.message;
      if (hashValue in this.savedProblems) { return; }
      this.savedProblems[hashValue] = true;
      const sampleRate = Math.max(1, (me.level()-2) * 2) * 0.01; // Reduce number of errors reported on earlier levels
      if (!(Math.random() < sampleRate)) { return; }
      // Save new problem
      const ucp = this.createUserCodeProblem(aether, aetherProblem);
      ucp.save();
      return null;
    }

    createUserCodeProblem(aether, aetherProblem) {
      const ucp = new UserCodeProblem();
      ucp.set('code', aether.raw);
      if (aetherProblem.range) {
        const rawLines = aether.raw.split('\n');
        const errorLines = rawLines.slice(aetherProblem.range[0].row, aetherProblem.range[1].row + 1);
        ucp.set('codeSnippet', errorLines.join('\n'));
      }
      if (aetherProblem.hint) { ucp.set('errHint', aetherProblem.hint); }
      if (aetherProblem.id) { ucp.set('errId', aetherProblem.id); }
      if (aetherProblem.errorCode) { ucp.set('errCode', aetherProblem.errorCode); }
      if (aetherProblem.level) { ucp.set('errLevel', aetherProblem.level); }
      if (aetherProblem.message) {
        let lineInfoMatch;
        ucp.set('errMessage', aetherProblem.message);
        // Save error message without 'Line N: ' prefix
        let messageNoLineInfo = aetherProblem.message;
        if (lineInfoMatch = messageNoLineInfo.match(/^Line [0-9]+\: /)) {
          messageNoLineInfo = messageNoLineInfo.slice(lineInfoMatch[0].length);
        }
        ucp.set('errMessageNoLineInfo', messageNoLineInfo);
      }
      if (aetherProblem.range) { ucp.set('errRange', aetherProblem.range); }
      if (aetherProblem.type) { ucp.set('errType', aetherProblem.type); }
      if (aether.language != null ? aether.language.id : undefined) { ucp.set('language', aether.language.id); }
      if (this.options.levelID) { ucp.set('levelID', this.options.levelID); }
      return ucp;
    }

    // Autocast (preload the world in the background):
    // Goes immediately if the code is a) changed and b) complete/valid and c) the cursor is at beginning or end of a line
    // We originally thought it would:
    // - Go after specified delay if a) and b) but not c)
    // - Go only when manually cast or deselecting a Thang when there are errors
    // But the error message display was delayed, so now trying:
    // - Go after specified delay if a) and not b) or c)
    guessWhetherFinished(aether) {
      const valid = !aether.getAllProblems().length;
      if (this.blocklyActive) { return true; }
      if (!valid) { return; }
      const cursorPosition = this.ace.getCursorPosition();
      const currentLine = _.string.rtrim(this.aceDoc.$lines[cursorPosition.row].replace(this.singleLineCommentRegex(), ''));  // trim // unless inside "
      const endOfLine = cursorPosition.column >= currentLine.length;  // just typed a semicolon or brace, for example
      const beginningOfLine = !currentLine.substr(0, cursorPosition.column).trim().length;  // uncommenting code, for example
      const incompleteThis = /^(s|se|sel|self|t|th|thi|this|g|ga|gam|game|h|he|her|hero)$/.test(currentLine.trim());
      //console.log "finished=#{valid and (endOfLine or beginningOfLine) and not incompleteThis}", valid, endOfLine, beginningOfLine, incompleteThis, cursorPosition, currentLine.length, aether, new Date() - 0, currentLine
      if (!incompleteThis && this.options.level.isType('game-dev')) {
        // TODO: Improve gamedev autocast speed
        return this.fetchTokenForSource().then(token => {
          // TODO: This is janky for those languages with a delay
          this.spell.transpile(token);
          return this.cast(false, false, true);
        });
      } else if ((endOfLine || beginningOfLine) && !incompleteThis) {
        return this.preload();
      }
    }

    singleLineCommentRegex() {
      let commentStart;
      if (this._singleLineCommentRegex) {
        this._singleLineCommentRegex.lastIndex = 0;
        return this._singleLineCommentRegex;
      }
      if (this.spell.language === 'html') {
        commentStart = `${utils.commentStarts.html}|${utils.commentStarts.css}|${utils.commentStarts.javascript}`;
      } else {
        commentStart = utils.commentStarts[this.spell.language] || '//';
      }
      this._singleLineCommentRegex = new RegExp(`[ \t]*(${commentStart})[^\"'\n]*`);
      return this._singleLineCommentRegex;
    }

    singleLineCommentOnlyRegex() {
      if (this._singleLineCommentOnlyRegex) {
        this._singleLineCommentOnlyRegex.lastIndex = 0;
        return this._singleLineCommentOnlyRegex;
      }
      this._singleLineCommentOnlyRegex = new RegExp( '^' + this.singleLineCommentRegex().source);
      return this._singleLineCommentOnlyRegex;
    }

    commentOutMyCode() {
      let comment;
      const prefix = ['javascript', 'java', 'cpp'].includes(this.spell.language) ? 'return;  ' : 'return  ';
      return comment = prefix + utils.commentStarts[this.spell.language];
    }

    preload() {
      // Send this code over to the God for preloading, but don't change the cast state.
      //console.log 'preload?', @spell.source.indexOf('while'), @spell.source.length, @spellThang?.castAether?.metrics?.statementsExecuted
      if (this.spell.source.indexOf('while') !== -1) { return; }  // If they're working with while-loops, it's more likely to be an incomplete infinite loop, so don't preload.
      if (this.spell.source.length > 500) { return; }  // Only preload on really short methods
      if (__guard__(__guard__(this.spellThang != null ? this.spellThang.castAether : undefined, x1 => x1.metrics), x => x.statementsExecuted) > 2000) { return; }  // Don't preload if they are running significant amounts of user code
      if (this.options.level.isType('web-dev')) { return; }
      const oldSource = this.spell.source;
      const oldSpellThangAether = this.spell.thang != null ? this.spell.thang.aether.serialize() : undefined;
      this.spell.transpile(this.getSource());
      this.cast(true);
      this.spell.source = oldSource;
      return (() => {
        const result = [];
        for (var key in oldSpellThangAether) {
          var value = oldSpellThangAether[key];
          result.push(this.spell.thang.aether[key] = value);
        }
        return result;
      })();
    }

    onAddUserSnippets() {
      if (this.spell.team === me.team) {
        return this.addUserSnippets(this.spell.getSource(), this.spell.language, __guardMethod__(this.ace, 'getSession', o => o.getSession()));
      }
    }

    onSpellCreated(e) {
      if (e.spell.team === me.team) {
        // ace session won't get correct language mode when created. so we wait for 1.5s
        return setTimeout(() => {
          return this.addUserSnippets(e.spell.getSource(), e.spell.language, __guardMethod__(this.ace, 'getSession', o => o.getSession()));
        }
        , 1500);
      }
    }

    onSpellChanged(e) {
      // TODO: Merge with updateHTML
      return this.spellHasChanged = true;
    }

    onAceMouseOut(e) {
      return Backbone.Mediator.publish("web-dev:stop-hovering-line", {});
    }

    onAceMouseMove(e) {
      if (this.destroyed) { return; }
      const {
        row
      } = e.getDocumentPosition();
      if (row === this.lastRowHovered) { return; } // Don't spam repeated messages for the same line
      this.lastRowHovered = row;
      const line = this.aceSession.getLine(row);
      Backbone.Mediator.publish("web-dev:hover-line", { row, line });
      return null;
    }

    onSessionWillSave(e) {
      if (!this.spellHasChanged || !me.isAdmin()) { return; }
      setTimeout(() => {
        if (!this.destroyed && !this.spellHasChanged) {
          return this.$el.find('.save-status').finish().show().fadeOut(2000);
        }
      }
      , 1000);
      return this.spellHasChanged = false;
    }

    onUserCodeProblem(e) {
      if (e.god !== this.options.god) { return; }
      if (e.problem.id === 'runtime_InfiniteLoop') { return this.onInfiniteLoop(e); }
      if (e.problem.userInfo.methodName !== this.spell.name) { return; }
      if ((this.spell.thang != null ? this.spell.thang.thang.id : undefined) !== e.problem.userInfo.thangID) { return; }
      return this.spell.hasChangedSignificantly(this.getSource(), null, hasChanged => {
        if (hasChanged) { return; }
        if (e.problem.type === 'runtime') {
          __guard__(this.spellThang != null ? this.spellThang.castAether : undefined, x => x.addProblem(e.problem));
        } else {
          this.spell.thang.aether.addProblem(e.problem);
        }
        this.lastUpdatedAetherSpellThang = null;  // force a refresh without a re-transpile
        return this.updateAether(false, false);
      });
    }

    onNonUserCodeProblem(e) {
      if (e.god !== this.options.god) { return; }
      if (!this.spellThang) { return; }
      const problem = this.spellThang.aether.createUserCodeProblem({type: 'runtime', kind: 'Unhandled', message: `Unhandled error: ${e.problem.message}`});
      this.spellThang.aether.addProblem(problem);
      if (this.spellThang.castAether != null) {
        this.spellThang.castAether.addProblem(problem);
      }
      this.lastUpdatedAetherSpellThang = null;  // force a refresh without a re-transpile
      return this.updateAether(false, false);  // TODO: doesn't work, error doesn't display
    }

    onInfiniteLoop(e) {
      if (!this.spellThang) { return; }
      this.spellThang.aether.addProblem(e.problem);
      if (this.spellThang.castAether != null) {
        this.spellThang.castAether.addProblem(e.problem);
      }
      this.lastUpdatedAetherSpellThang = null;  // force a refresh without a re-transpile
      return this.updateAether(false, false);
    }

    onNewWorld(e) {
      return this.fetchTokenForSource().then(token => {
        let thang;
        if (thang = e.world.getThangByID(this.spell.thang != null ? this.spell.thang.thang.id : undefined)) {
          const aether = e.world.userCodeMap[thang.id] != null ? e.world.userCodeMap[thang.id][this.spell.name] : undefined;
          this.spell.thang.castAether = aether;
          this.spell.thang.aether = this.spell.createAether(thang);
          //console.log thang.id, @spell.spellKey, 'ran', aether.metrics.callsExecuted, 'times over', aether.metrics.statementsExecuted, 'statements, with max recursion depth', aether.metrics.maxDepth, 'and full flow/metrics', aether.metrics, aether.flow
        } else {
          this.spell.thang = null;
        }


        this.spell.transpile(token);
        return this.updateAether(false, false);
      });
    }

    // --------------------------------------------------------------------------------------------------

    focus() {
      // TODO: it's a hack checking if a modal is visible; the events should be removed somehow
      // but this view is not part of the normal subview destroying because of how it's swapped
      if (!this.controlsEnabled || !this.writable || ($('.modal:visible, .shepherd-button:visible').length !== 0)) { return; }
      if (this.ace.isFocused()) { return; }
      if (__guard__(me.get('aceConfig'), x => x.screenReaderMode) && utils.isOzaria) { return; }  // Screen reader users get to control their own focus manually
      if (this.blocklyActive) { return; }
      this.ace.focus();
      return this.ace.clearSelection();
    }

    onFrameChanged(e) {
      if (!this.spellThang || ((e.selectedThang != null ? e.selectedThang.id : undefined) !== (this.spellThang != null ? this.spellThang.thang.id : undefined))) { return; }
      this.thang = e.selectedThang;  // update our thang to the current version
      return this.highlightCurrentLine();
    }

    onCoordinateSelected(e) {
      if (!this.ace.isFocused() || (e.x == null) || (e.y == null)) { return; }
      if (this.spell.language === 'python') {
        this.ace.insert(`{\"x\": ${e.x}, \"y\": ${e.y}}`);
      } else if (this.spell.language === 'lua') {
        this.ace.insert(`{x=${e.x}, y=${e.y}}`);
      } else {
        this.ace.insert(`{x: ${e.x}, y: ${e.y}}`);
      }
      return this.highlightCurrentLine();
    }

    onStatementIndexUpdated(e) {
      if (e.ace !== this.ace) { return; }
      return this.highlightCurrentLine();
    }

    highlightCurrentLine(flow) {
      // TODO: move this whole thing into SpellDebugView or somewhere?
      let callNumber, markerRange, row, state;
      let asc, end1;
      if (!this.destroyed) { this.highlightEntryPoints(); }
      if (flow == null) { flow = __guard__(this.spellThang != null ? this.spellThang.castAether : undefined, x => x.flow); }
      if (!flow || !this.thang) { return; }
      const executed = [];
      const executedRows = {};
      let matched = false;
      const states = flow.states != null ? flow.states : [];
      let currentCallIndex = null;
      for (callNumber = 0; callNumber < states.length; callNumber++) {
        var callState = states[callNumber];
        if ((currentCallIndex == null) && ((callState.userInfo != null ? callState.userInfo.time : undefined) > this.thang.world.age)) {
          currentCallIndex = callNumber - 1;
        }
        if (matched) {
          executed.pop();
          break;
        }
        executed.push([]);
        for (var statementNumber = 0; statementNumber < callState.statements.length; statementNumber++) {
          state = callState.statements[statementNumber];
          if ((state.userInfo != null ? state.userInfo.time : undefined) > this.thang.world.age) {
            matched = true;
            break;
          }
          _.last(executed).push(state);
          executedRows[state.range[0].row] = true;
        }
      }
      //state.executing = true if state.userInfo?.time is @thang.world.age  # no work
      if (currentCallIndex == null) { currentCallIndex = callNumber - 1; }
      //console.log 'got call index', currentCallIndex, 'for time', @thang.world.age, 'out of', states.length

      this.decoratedGutter = this.decoratedGutter || {};

      if (this.aceSession == null) { return; }

      // TODO: don't redo the markers if they haven't actually changed
      for (markerRange of Array.from((this.markerRanges != null ? this.markerRanges : (this.markerRanges = [])))) {
        markerRange.start.detach();
        markerRange.end.detach();
        this.aceSession.removeMarker(markerRange.id);
      }
      this.markerRanges = [];
      for (row = 0, end1 = this.aceSession.getLength(), asc = 0 <= end1; asc ? row < end1 : row > end1; asc ? row++ : row--) {
        if (!executedRows[row]) {
          this.aceSession.removeGutterDecoration(row, 'executing');
          this.aceSession.removeGutterDecoration(row, 'executed');
          this.decoratedGutter[row] = '';
        }
      }
      let lastExecuted = _.last(executed);
      let showToolbarView = executed.length && (this.spellThang.castAether.metrics.statementsExecuted > 3) && !this.options.level.get('hidesCodeToolbar');  // Hide for a while
      showToolbarView = false;  // TODO: fix toolbar styling in new design to have some space for it

      if (showToolbarView) {
        const statementIndex = Math.max(0, lastExecuted.length - 1);
        if (this.toolbarView != null) {
          this.toolbarView.toggleFlow(true);
        }
        if (this.toolbarView != null) {
          this.toolbarView.setCallState(states[currentCallIndex], statementIndex, currentCallIndex, this.spellThang.castAether.metrics);
        }
        if ((this.toolbarView != null ? this.toolbarView.statementIndex : undefined) != null) { lastExecuted = lastExecuted.slice(0 , + this.toolbarView.statementIndex + 1 || undefined); }
      } else {
        if (this.toolbarView != null) {
          this.toolbarView.toggleFlow(false);
        }
        if (this.debugView != null) {
          this.debugView.setVariableStates({});
        }
      }
      const marked = {};
      let gotVariableStates = false;
      const iterable = lastExecuted != null ? lastExecuted : [];
      for (let i = 0; i < iterable.length; i++) {
        var markerType;
        state = iterable[i];
        var [start, end] = Array.from(state.range);
        var clazz = i === (lastExecuted.length - 1) ? 'executing' : 'executed';
        if (clazz === 'executed') {
          if (marked[start.row]) { continue; }
          marked[start.row] = true;
          markerType = 'fullLine';
        } else {
          if (this.debugView != null) {
            this.debugView.setVariableStates(state.variables);
          }
          gotVariableStates = true;
          markerType = 'text';
        }
        markerRange = new Range(start.row, start.col, end.row, end.col);
        markerRange.start = this.aceDoc.createAnchor(markerRange.start);
        markerRange.end = this.aceDoc.createAnchor(markerRange.end);
        markerRange.id = this.aceSession.addMarker(markerRange, clazz, markerType);
        this.markerRanges.push(markerRange);
        if (executedRows[start.row] && (this.decoratedGutter[start.row] !== clazz)) {
          if (this.decoratedGutter[start.row] !== '') { this.aceSession.removeGutterDecoration(start.row, this.decoratedGutter[start.row]); }
          this.aceSession.addGutterDecoration(start.row, clazz);
          this.decoratedGutter[start.row] = clazz;
          if (application.isIPadApp) { Backbone.Mediator.publish("tome:highlight-line", {line:start.row}); }
          var $cinematicParent = $('#cinematic-code-display');
          var highlightedIndex = 0;
          for (var start1 = end.row - 3, sourceLineNumber = start1, end2 = end.row + 3, asc1 = start1 <= end2; asc1 ? sourceLineNumber <= end2 : sourceLineNumber >= end2; asc1 ? sourceLineNumber++ : sourceLineNumber--) {
            var codeLine = _.string.rtrim(this.aceDoc.$lines[sourceLineNumber]);
            var $codeLineEl = $cinematicParent.find(`.code-line-${highlightedIndex++}`);
            utils.replaceText($codeLineEl.find('.line-number'), sourceLineNumber >= 0 ? sourceLineNumber + 1 : '');
            utils.replaceText($codeLineEl.find('.indentation'), codeLine.match(/\s*/)[0]);
            utils.replaceText($codeLineEl.find('.code-text'), _.string.trim(codeLine));
          }
        }
      }

      if (!gotVariableStates) { if (this.debugView != null) {
        this.debugView.setVariableStates({});
      } }
      return null;
    }

    highlightEntryPoints() {
      // Put a yellow arrow in the gutter pointing to each place we expect them to put in code.
      // Usually, this is indicated by a blank line after a comment line, except for the first comment lines.
      // If we need to indicate an entry point on a line that has code, we use ∆ in a comment on that line.
      // If the entry point line has been changed (beyond the most basic shifted lines), we don't point it out.
      if (this.aceDoc == null) { return; }
      const lines = this.aceDoc.$lines;
      const originalLines = this.spell.originalSource.split('\n');
      const session = this.aceSession;
      const commentStart = utils.commentStarts[this.spell.language] || '//';
      let seenAnEntryPoint = false;
      let previousLine = null;
      let previousLineHadComment = false;
      let previousLineHadCode = false;
      let previousLineWasBlank = false;
      let pastIntroComments = false;
      return (() => {
        const result = [];
        for (let index = 0; index < lines.length; index++) {
          var line = lines[index];
          session.removeGutterDecoration(index, 'entry-point');
          session.removeGutterDecoration(index, 'next-entry-point');
          for (var i of [0, 4, 8, 12, 16]) { session.removeGutterDecoration(index, `entry-point-indent-${i}`); }

          var lineHasComment = this.singleLineCommentRegex().test(line);
          var lineHasCode = line.trim()[0] && !this.singleLineCommentOnlyRegex().test(line);
          var lineIsBlank = /^[ \t]*$/.test(line);
          var lineHasExplicitMarker = /[Δ∆]/.test(line);  // Two different identical-seeming delta codepoints

          var originalLine = originalLines[index];
          var lineHasChanged = line !== originalLine;

          var isEntryPoint = lineIsBlank && previousLineHadComment && !previousLineHadCode && pastIntroComments;
          if (isEntryPoint && lineHasChanged) {
            // It might just be that the line was shifted around by the player inserting more code.
            // We also look for the unchanged comment line in a new position to find what line we're really on.
            var movedIndex = originalLines.indexOf(previousLine);
            if ((movedIndex !== -1) && (line === originalLines[movedIndex + 1])) {
              lineHasChanged = false;
            } else {
              isEntryPoint = false;
            }
          }

          if (lineHasExplicitMarker) {
            if (lineHasChanged) {
              if (originalLines.indexOf(line) !== -1) {
                lineHasChanged = false;
                isEntryPoint = true;
              }
            } else {
              isEntryPoint = true;
            }
          }

          if (isEntryPoint) {
            session.addGutterDecoration(index, 'entry-point');
            if (!seenAnEntryPoint) {
              session.addGutterDecoration(index, 'next-entry-point');
              seenAnEntryPoint = true;
              if (!this.hasSetInitialCursor) {
                var left;
                this.hasSetInitialCursor = true;
                this.ace.navigateTo(index, (left = __guard__(line.match(/\S/), x => x.index)) != null ? left : line.length);
                this.firstEntryToScrollLine = index;
              }
            }

            // Shift pointer right based on current indentation
            // TODO: tabs probably need different horizontal offsets than spaces
            var indent = 0;
            while (/\s/.test(line[indent])) { indent++; }
            indent = Math.min(16, Math.floor(indent / 4) * 4);
            session.addGutterDecoration(index, `entry-point-indent-${indent}`);
          }

          previousLine = line;
          previousLineHadComment = lineHasComment;
          previousLineHadCode = lineHasCode;
          previousLineWasBlank = lineIsBlank;
          result.push(pastIntroComments || (pastIntroComments = lineHasCode || previousLineWasBlank));
        }
        return result;
      })();
    }

    onAnnotationClick() {
      // @ is the gutter element
      return Backbone.Mediator.publish('tome:jiggle-problem-alert', {});
    }

    onGutterClick() {
      return this.ace.clearSelection();
    }

    onDisableControls(e) { return this.toggleControls(e, false); }
    onEnableControls(e) { return this.toggleControls(e, this.writable); }
    toggleControls(e, enabled) {
      if (this.destroyed) { return; }
      if ((e != null ? e.controls : undefined) && !(Array.from(e.controls).includes('editor'))) { return; }
      if (enabled === this.controlsEnabled) { return; }
      this.controlsEnabled = enabled && this.writable;
      const disabled = !enabled;
      const wasFocused = this.ace.isFocused();
      this.ace.setReadOnly(disabled);
      this.ace[disabled ? 'setStyle' : 'unsetStyle']('disabled');
      this.toggleBackground();
      if (disabled && wasFocused) { return $('body').focus(); }
    }

    toggleBackground() {
      // TODO: make the background an actual background and do the CSS trick
      // used in spell-top-bar-view.sass for disabling
      const background = this.$el.find('img.code-background')[0];
      if (background.naturalWidth === 0) {  // not loaded yet
        return _.delay(this.toggleBackground, 100);
      }
      if (this.controlsEnabled) { filters.revertImage(background, 'span.code-background'); }
      if (!this.controlsEnabled) { return filters.darkenImage(background, 'span.code-background', 0.8); }
    }

    onSpellBeautify(e) {
      if (!this.spellThang || (!this.ace.isFocused() && (e.spell !== this.spell))) { return; }
      const ugly = this.getSource();
      const pretty = this.spellThang.aether.beautify(ugly.replace(/\bloop\b/g, 'while (__COCO_LOOP_CONSTRUCT__)')).replace(/while \(__COCO_LOOP_CONSTRUCT__\)/g, 'loop');
      return this.ace.setValue(pretty);
    }

    onFixCode(e) {
      this.ace.setValue(e.code);
      this.ace.clearSelection();
      return this.recompile();
    }

    onFixCodePreviewStart(e) {
      // TODO: show a diff view instead of just setting the code
      this.codeBeforePreview = this.getSource();
      this.updateACEText(e.code);
      return this.ace.clearSelection();
    }

    onFixCodePreviewEnd(e) {
      this.updateACEText(this.codeBeforePreview);
      return this.ace.clearSelection();
    }

    fillACESolution() {
      let solution;
      this.aceSolution = ace.edit(document.querySelector('.ace-solution'));
      const aceSSession = this.aceSolution.getSession();
      aceSSession.setMode(aceUtils.aceEditModes[this.spell.language]);
      this.aceSolution.setTheme('ace/theme/textmate');
      if (this.teaching) {
        solution = store.getters['game/getSolutionSrc'](this.spell.language);
      } else {
        solution = '';
      }
      this.aceSolution.setValue(solution);
      this.aceSolution.clearSelection();
      this.aceSolutionLastLineCount = 0;
      this.updateSolutionLines = _.throttle(this.updateSolutionLines, 1000);

      this.aceDiff = new AceDiff({
        element: '#solution-view',
        showDiffs: false,
        showConnectors: true,
        mode: aceUtils.aceEditModes[this.spell.language],
        left: {
          ace: this.aceSolution,
          editable: false,
          copyLinkEnabled: false
        },
        right: {
          ace: this.ace,
          copyLinkEnabled: false
        }
      });

      return aceSSession.on('changeBackMarker', () => {
        if (this.aceDiff && (this.aceDiff.getNumDiffs() === 0)) {
          return Backbone.Mediator.publish('level:close-solution', { removeButton: true });
        }
      });
    }

    onUpdateSolution(e){
      if (!this.aceDiff) { return; }
      this.aceSolution.setValue(e.code);
      this.aceSolution.clearSelection();
      const lineCount = e.code.split('\n').length;
      // if lineCount > @aceSolutionLastLineCount
        // @aceSolutionLastLineCount = lineCount
      this.updateSolutionLines(lineCount, this.aceSolution, '.ace-solution', '#solution-area');
      return this.aceSolution.resize(true);
    }

    onStreamingSolution(e) {
      if (e.finish) {
        this.solutionStreaming = false;
      } else {
        this.solutionStreaming = true;
      }
      const solution = document.querySelector('#solution-area');
      if (solution.classList.contains('display')) {
        return this.aceDiff.setOptions({showDiffs: (e.finish != null)});
      }
    }

    onToggleSolution(e){
      console.log('on toggle solution', e, this.aceDiff);
      if (!this.aceDiff) { return; }
      if (e.code) {
        this.onUpdateSolution(e);
      }
      const solution = document.querySelector('#solution-area');
      if (solution.classList.contains('display')) {
        solution.classList.remove('display');
        solution.style.opacity = 0;
      } else {
        solution.classList.add('display');
        solution.style.opacity = 1;
        Backbone.Mediator.publish('tome:hide-problem-alert', {});
      }
      if (this.solutionStreaming) { return; }
      return this.aceDiff.setOptions({showDiffs: solution.classList.contains('display')});
    }

    closeSolution() {
      const solution = document.querySelector('#solution-area');
      if (solution.classList.contains('display')) {
        solution.classList.remove('display');
        this.aceDiff.setOptions({showDiffs: false});
        return setTimeout(() => {
          return solution.style.opacity = 0;
        }
        , 1000);
      }
    }

    onMaximizeToggled(e) {
      return _.delay((() => this.resize()), 500 + 100);  // Wait $level-resize-transition-time, plus a bit.
    }

    onToggleBlocks(e) {
      if (e.blocks && this.blocklyActive) { return; }
      if (!e.blocks && !this.blocklyActive) { return; }
      if (e.blocks && this.blockly) {
        // Show it
        this.blocklyActive = true;
      } else if (e.blocks) {
        // Create it
        this.addBlockly();
      } else if (this.blockly) {
        // Hide it
        this.awaitingBlockly = false;
        this.blocklyActive = false;
      }
      return this.resize();
    }

    onWindowResize(e) {
      this.spellPaletteHeight = null;
      //$('#spell-palette-view').css 'height', 'auto'  # Let it go back to controlling its own height
      return _.delay((() => (typeof this.resize === 'function' ? this.resize() : undefined)), 500 + 100);  // Wait $level-resize-transition-time, plus a bit.
    }

    resize() {
      if (this.ace != null) {
        this.ace.resize(true);
      }
      this.lastScreenLineCount = null;
      this.updateLines();
      return this.resizeBlockly();
    }

    resizeBlockly(repeat) {
      if (repeat == null) { repeat = true; }
      if (!this.blocklyActive) { return; }
      Blockly.svgResize(this.blockly);
      if (repeat) {
        this.scrollBlocklyToTopLeft();
        return _.delay((() => (typeof this.resizeBlockly === 'function' ? this.resizeBlockly(false) : undefined)), 500 + 100);  // Wait $level-resize-transition-time, plus a bit, again!
      }
    }

    scrollBlocklyToTopLeft() {
      const metrics = this.blockly.getMetrics();
      return this.blockly.scroll(-metrics.contentLeft + 30, -metrics.contentTop + 50);
    }

    onChangeEditorConfig(e) {
      let left;
      const aceConfig = (left = me.get('aceConfig')) != null ? left : {};
      this.ace.setBehavioursEnabled(aceConfig.behaviors);
      this.ace.setKeyboardHandler(this.keyBindings[aceConfig.keyBindings != null ? aceConfig.keyBindings : 'default']);
      return this.updateAutocomplete(aceConfig.liveCompletion != null ? aceConfig.liveCompletion : false);
    }

    onChangeLanguage(e) {
      if (!this.spell.canWrite()) { return; }
      this.aceSession.setMode(aceUtils.aceEditModes[e.language]);
      if (this.autocomplete != null) {
        this.autocomplete.set('language', aceUtils.aceEditModes[e.language].substr('ace/mode/'));
      }
      const wasDefault = this.getSource() === this.spell.originalSource;
      this.spell.setLanguage(e.language);
      if (wasDefault) { return this.reloadCode(true); }
    }

    onInsertSnippet(e) {
      let snippetCode = null;
      if (__guard__(e.doc.snippets != null ? e.doc.snippets[e.language] : undefined, x => x.code)) {
        snippetCode = e.doc.snippets[e.language].code;
      } else if ((e.formatted.type !== 'snippet') && (e.formatted.shortName != null)) {
        snippetCode = e.formatted.shortName;
      }
      if (snippetCode == null) { return; }
      const {
        snippetManager
      } = ace.require('ace/snippets');
      snippetManager.insertSnippet(this.ace, snippetCode);
    }

    dismiss() {
      return this.spell.hasChangedSignificantly(this.getSource(), null, hasChanged => {
        if (hasChanged) { return this.recompile(); }
      });
    }

    onScriptStateChange(e) {
      return this.scriptRunning = e.currentScript === null ? false : true;
    }

    onPlaybackEndedChanged(e) {
      return $(this.ace != null ? this.ace.container : undefined).toggleClass('playback-ended', e.ended);
    }

    onGatherChatMessageContext(e) {
      let level, problem;
      const {
        context
      } = e.chat;
      context.codeLanguage = this.spell.language || 'python';
      if (level = this.options.level) {
        context.levelOriginal = level.get('original');
        context.levelName = level.get('displayName') || level.get('name');
        if (e.chat.example) {
          if (context.i18n == null) { context.i18n = {}; }
          const object = level.get('i18n');
          for (var language in object) {
            var levelNameTranslation;
            var translations = object[language];
            if (levelNameTranslation = translations.name) {
              if (context.i18n[language] == null) { context.i18n[language] = {}; }
              context.i18n[language].levelName = levelNameTranslation;
            }
          }
        }
      }

      const aether = this.displayedAether;  // TODO: maybe use @spellThang.aether?
      const isCast = (this.displayedAether === this.spellThang.aether) || !_.isEmpty(aether.metrics) || _.some(aether.getAllProblems(), {type: 'runtime'});
      const newProblems = this.convertAetherProblems(aether, aether.getAllProblems(), false); // do not cast the problem here
      if (problem = newProblems[0]) {
        const ucp = this.createUserCodeProblem(aether, problem.aetherProblem);
        context.error = _.pick({
          codeSnippet: ucp.get('codeSnippet'),
          hint: ucp.get('errHint'),
          id: ucp.get('errId'),
          errorCode: ucp.get('errCode'),
          level: ucp.get('errLevel'),
          message: ucp.get('errMessage'),
          messageNoLineInfo: ucp.get('errMessageNoLineInfo'),
          range: ucp.get('errRange'),
          type: ucp.get('errType'),
          i18nParams: problem.i18nParams
        }
        , v => v !== undefined);
      }

      const spellContext = this.spell.createChatMessageContext(e.chat);
      return _.assign(context, spellContext);
    }

    checkRequiredCode() {
      if (this.destroyed) { return; }
      const source = this.getSource().replace(this.singleLineCommentRegex(), '');
      const requiredCodeFragments = this.options.level.get('requiredCode');
      return (() => {
        const result = [];
        for (var requiredCodeFragment of Array.from(requiredCodeFragments)) {
        // Could make this obey regular expressions like suspectCode if needed
          if (source.indexOf(requiredCodeFragment) === -1) {
            if (this.warnedCodeFragments == null) { this.warnedCodeFragments = {}; }
            if (!this.warnedCodeFragments[requiredCodeFragment]) {
              Backbone.Mediator.publish('tome:required-code-fragment-deleted', {codeFragment: requiredCodeFragment});
            }
            result.push(this.warnedCodeFragments[requiredCodeFragment] = true);
          } else {
            result.push(undefined);
          }
        }
        return result;
      })();
    }

    checkSuspectCode() {
      if (this.destroyed) { return; }
      const source = this.getSource().replace(this.singleLineCommentRegex(), '');
      const suspectCodeFragments = this.options.level.get('suspectCode');
      const detectedSuspectCodeFragmentNames = [];
      for (var suspectCodeFragment of Array.from(suspectCodeFragments)) {
        var pattern = new RegExp(suspectCodeFragment.pattern, 'm');
        if (pattern.test(source)) {
          if (this.warnedCodeFragments == null) { this.warnedCodeFragments = {}; }
          if (!this.warnedCodeFragments[suspectCodeFragment.name]) {
            Backbone.Mediator.publish('tome:suspect-code-fragment-added', {codeFragment: suspectCodeFragment.name, codeLanguage: this.spell.language});
          }
          this.warnedCodeFragments[suspectCodeFragment.name] = true;
          detectedSuspectCodeFragmentNames.push(suspectCodeFragment.name);
        }
      }
      for (var lastDetectedSuspectCodeFragmentName of Array.from(this.lastDetectedSuspectCodeFragmentNames != null ? this.lastDetectedSuspectCodeFragmentNames : [])) {
        if (!Array.from(detectedSuspectCodeFragmentNames).includes(lastDetectedSuspectCodeFragmentName)) {
          Backbone.Mediator.publish('tome:suspect-code-fragment-deleted', {codeFragment: lastDetectedSuspectCodeFragmentName, codeLanguage: this.spell.language});
        }
      }
      return this.lastDetectedSuspectCodeFragmentNames = detectedSuspectCodeFragmentNames;
    }

    onAskingHelp(e) {
      if (utils.useWebsocket) {
        const {
          msg
        } = e;
        msg.info.url += `?course=${this.courseID}&codeLanguage=${this.session.get('codeLanguage')}&session=${this.session.id}&teaching=true`;
        return fetchJson(`/db/level.session/${this.session.id}/permissions/ws/${msg.to}`, { method: 'PUT' }).then(() => {
          if (this.yjsProvider && this.yjsProvide.wsconnected) {
            return globalVar.application.wsBus.ws.sendJSON(msg);
          } else {
            this.yjsProvider = aceUtils.setupCRDT(`${this.session.id}`, me.broadName(), this.getSource(), this.ace, () => globalVar.application.wsBus.ws.sendJSON(msg));
            this.yjsProvider.connections = 1;
            return this.yjsProvider.awareness.on('change', () => {
              this.yjsProvider.connections = this.yjsProvider.awareness.getStates().size;
              return console.log('provider get awareness update:', this.yjsProvider.connections);
            });
          }
        });
      }
    }

    destroy() {
      $(this.ace != null ? this.ace.container : undefined).find('.ace_gutter').off('click mouseenter', '.ace_error, .ace_warning, .ace_info');
      $(this.ace != null ? this.ace.container : undefined).find('.ace_gutter').off();
      if (this.firepad != null) {
        this.firepad.dispose();
      }
      if (this.blockly != null) {
        this.blockly.dispose();
      }
      for (var command of Array.from(this.aceCommands)) { if (this.ace != null) {
        this.ace.commands.removeCommand(command);
      } }
      if (this.ace != null) {
        this.ace.destroy();
      }
      if (this.aceDoc != null) {
        this.aceDoc.off('change', this.onCodeChangeMetaHandler);
      }
      if (this.aceSession != null) {
        this.aceSession.selection.off('changeCursor', this.onCursorActivity);
      }
      this.destroyAceEditor(this.ace);
      if (this.debugView != null) {
        this.debugView.destroy();
      }
      if (this.translationView != null) {
        this.translationView.destroy();
      }
      if (this.toolbarView != null) {
        this.toolbarView.destroy();
      }
      if (this.editorLang != null) { if (this.autocomplete != null) {
        this.autocomplete.addSnippets([], this.editorLang);
      } }
      $(window).off('resize', this.onWindowResize);
      if (this.spade != null) {
        this.spade.createUIEvent("destroying-view");
      }
      this.saveSpade();
      window.clearTimeout(this.saveSpadeTimeout);
      this.saveSpadeTimeout = null;
      if (this.autocomplete != null) {
        this.autocomplete.destroy();
      }
      return super.destroy();
    }
  };
  SpellView.initClass();
  return SpellView;
})());

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