/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let Spell;
const SpellView = require('./SpellView');
const SpellTopBarView = require('./SpellTopBarView');
const {me} = require('core/auth');
const { createAetherOptions, replaceSimpleLoops } = require('lib/aether_utils');
const { translateJS } = require('lib/translate-utils');
const utils = require('core/utils');

module.exports = (Spell = (function() {
  Spell = class Spell {
    static initClass() {
      this.prototype.loaded = false;
      this.prototype.view = null;
      this.prototype.topBarView = null;
    }

    constructor(options) {
      this.spellKey = options.spellKey;
      this.pathComponents = options.pathComponents;
      this.session = options.session;
      this.otherSession = options.otherSession;
      this.spectateView = options.spectateView;
      this.observing = options.observing;
      this.supermodel = options.supermodel;
      this.skipProtectAPI = options.skipProtectAPI;
      this.worker = options.worker;
      this.level = options.level;
      this.createFromProgrammableMethod(options.programmableMethod, options.language);
      if (this.canRead()) {  // We can avoid creating these views if we'll never use them.
        this.view = new SpellView({spell: this, level: options.level, session: this.session, otherSession: this.otherSession, worker: this.worker, god: options.god, supermodel: this.supermodel, levelID: options.levelID, classroomAceConfig: options.classroomAceConfig, spectateView: this.spectateView, courseID: options.courseID, blocks: options.blocks});
        this.view.render();  // Get it ready and code loaded in advance
        this.topBarView = new SpellTopBarView({
          hintsState: options.hintsState,
          spell: this,
          supermodel: this.supermodel,
          codeLanguage: this.language,
          level: options.level,
          session: options.session,
          courseID: options.courseID,
          courseInstanceID: options.courseInstanceID,
          blocks: options.blocks,
          blocksHidden: options.blocksHidden,
          teacherID: options.teacherID
        });
        this.topBarView.render();
      }
      Backbone.Mediator.publish('tome:spell-created', {spell: this});
    }

    createFromProgrammableMethod(programmableMethod, codeLanguage) {
      let sessionSource;
      const p = programmableMethod;
      this.commentI18N = p.i18n;
      this.commentContext = p.context;
      if (p.sourceVariants) {
        this.languages = _.clone(_.sample(p.sourceVariants));
      } else {
        this.languages = p.languages != null ? p.languages : {};
      }
      if (this.languages.javascript == null) { this.languages.javascript = p.source; }
      this.name = p.name;
      this.permissions = {read: (p.permissions != null ? p.permissions.read : undefined) != null ? (p.permissions != null ? p.permissions.read : undefined) : [], readwrite: (p.permissions != null ? p.permissions.readwrite : undefined) != null ? (p.permissions != null ? p.permissions.readwrite : undefined) : ['humans']};  // teams
      this.team = this.permissions.readwrite[0] != null ? this.permissions.readwrite[0] : 'common';
      if (this.canWrite()) {
        this.setLanguage(codeLanguage);
      } else if (this.otherSession && (this.team === this.otherSession.get('team'))) {
        this.setLanguage(this.otherSession.get('submittedCodeLanguage') || this.otherSession.get('codeLanguage'));
      } else {
        this.setLanguage('javascript');
      }

      this.source = this.originalSource;
      this.parameters = p.parameters;
      if (this.otherSession && (this.team === this.otherSession.get('team')) && (sessionSource = this.otherSession.getSourceFor(this.spellKey))) {
        // Load opponent code from other session (new way, not relying on PlayLevelView loadOpponentTeam)
        this.source = replaceSimpleLoops(sessionSource, this.language);
      } else if (this.permissions.readwrite.length && (sessionSource = this.session.getSourceFor(this.spellKey))) {
        // Load either our code or opponent code (old way, opponent code copied into our session in PlayLevelView loadOpponentTeam)
        if (sessionSource !== '// Should fill in some default source\n') {  // TODO: figure out why session is getting this default source in there and stop it
          this.source = replaceSimpleLoops(sessionSource, this.language);
        }
      }
      if (p.aiSource && !this.otherSession && !this.canWrite()) {
        this.source = (this.originalSource = p.aiSource);
        return this.isAISource = true;
      }
    }

    destroy() {
      if (this.view != null) {
        this.view.destroy();
      }
      if (this.topBarView != null) {
        this.topBarView.destroy();
      }
      this.thang = null;
      return this.worker = null;
    }

    setLanguage(language) {
      this.language = language;
      if (this.level.isType('web-dev')) { this.language = 'html'; }
      this.displayCodeLanguage = utils.capitalLanguages[this.language];
      if (['cpp', 'java', 'lua', 'coffeescript', 'python'].includes(this.language) && !this.languages[this.language]) {
        this.languages[this.language] = translateJS(this.languages.javascript, this.language);
      }
      this.originalSource = this.languages[this.language] != null ? this.languages[this.language] : this.languages.javascript;
      if (window.serverConfig.picoCTF) { this.originalSource = this.addPicoCTFProblem(); }

      if (this.level.isType('web-dev')) {
        // Pull apart the structural wrapper code and the player code, remember the wrapper code, and strip indentation on player code.
        const playerCode = utils.extractPlayerCodeTag(this.originalSource);
        this.wrapperCode = this.originalSource.replace(/<playercode>[\s\S]*<\/playercode>/, '☃');  // ☃ serves as placeholder for constructHTML
        this.originalSource = playerCode;
      }

      // Translate comments chosen spoken language.
      if (!this.commentContext) { return; }
      const context = $.extend(true, {}, this.commentContext);
      const spokenLanguage = me.get('preferredLanguage');
      this.originalSource = this.translateCommentContext({source: this.originalSource, commentContext: this.commentContext, commentI18N: this.commentI18N, spokenLanguage, codeLanguage: this.language});
      this.wrapperCode = this.translateCommentContext({source: this.wrapperCode, commentContext: this.commentContext, commentI18N: this.commentI18N, spokenLanguage, codeLanguage: this.language});

      if (/loop/.test(this.originalSource) && this.level.isType('course', 'course-ladder', 'hero', 'hero-ladder')) {
        // Temporary hackery to make it look like we meant while True: in our sample code until we can update everything
        return this.originalSource = replaceSimpleLoops(this.originalSource, this.language);
      }
    }

    translateCommentContext({ source, commentContext, commentI18N, codeLanguage, spokenLanguage }) {
      let translatedSource;
      commentContext = $.extend(true, {}, commentContext);

      if (codeLanguage === 'lua') {
        for (var k in commentContext) {
          var v = commentContext[k];
          commentContext[k] = v.replace(/\b([a-zA-Z]+)\.([a-zA-Z_]+\()/, '$1:$2');
        }
      }

      if (commentI18N) {
        while (spokenLanguage) {
          var spokenLanguageContext;
          if (fallingBack != null) { spokenLanguage = spokenLanguage.substr(0, spokenLanguage.lastIndexOf('-')); }
          if (spokenLanguageContext = commentI18N[spokenLanguage] != null ? commentI18N[spokenLanguage].context : undefined) {
            commentContext = _.merge(commentContext, spokenLanguageContext);
            break;
          }
          var fallingBack = true;
        }
      }
      try {
        translatedSource = _.template(source, commentContext);
      } catch (e) {
        console.error("Couldn't create example code template of", source, "\nwith commentContext", commentContext, "\nError:", e);
        translatedSource = source;
      }
      return translatedSource;
    }

    untranslateCommentContext({ source, commentContext, commentI18N, codeLanguage, spokenLanguage }) {
      let k, v;
      commentContext = $.extend(true, {}, commentContext);

      if (codeLanguage === 'lua') {
        for (k in commentContext) {
          v = commentContext[k];
          commentContext[k] = v.replace(/\b([a-zA-Z]+)\.([a-zA-Z_]+\()/, '$1:$2');
        }
      }

      if (commentI18N) {
        while (spokenLanguage) {
          var spokenLanguageContext;
          if (fallingBack != null) { spokenLanguage = spokenLanguage.substr(0, spokenLanguage.lastIndexOf('-')); }
          if (spokenLanguageContext = commentI18N[spokenLanguage] != null ? commentI18N[spokenLanguage].context : undefined) {
            commentContext = _.merge(commentContext, spokenLanguageContext);
            break;
          }
          var fallingBack = true;
        }
      }
      for (k in commentContext) {
        v = commentContext[k];
        source = source.replace(v, `<%= ${k} %>`);
      }
      return source;
    }

    getSolution(codeLanguage) {
      let left;
      const hero = _.find(((left = this.level.get('thangs')) != null ? left : []), {id: 'Hero Placeholder'});
      const component = _.find(hero.components != null ? hero.components : [], x => __guard__(__guard__(x != null ? x.config : undefined, x2 => x2.programmableMethods), x1 => x1.plan));
      const plan = __guard__(component.config != null ? component.config.programmableMethods : undefined, x => x.plan);
      const solutions = _.filter(((plan != null ? plan.solutions : undefined) != null ? (plan != null ? plan.solutions : undefined) : []), s => !s.testOnly && s.succeeds);
      const rawSource = __guard__(_.find(solutions, {language: codeLanguage}), x1 => x1.source);
      return rawSource;
    }

    constructHTML(source) {
      return this.wrapperCode.replace('☃', source);
    }

    addPicoCTFProblem() {
      let problem;
      if (!(problem = this.level.picoCTFProblem)) { return this.originalSource; }
      const description = `\
-- ${problem.name} --
${problem.description}\
`.replace(/<p>(.*?)<\/p>/gi, '$1');
      return (Array.from(description.split('\n')).map((line) => `// ${line}`)).join('\n') + '\n' + this.originalSource;
    }

    addThang(thang) {
      if ((this.thang != null ? this.thang.thang.id : undefined) === thang.id) {
        return this.thang.thang = thang;
      } else {
        return this.thang = {thang, aether: this.createAether(thang), castAether: null};
      }
    }

    removeThangID(thangID) {
      if ((this.thang != null ? this.thang.thang.id : undefined) === thangID) { return this.thang = null; }
    }

    canRead(team) {
      return Array.from(this.permissions.read).includes((team != null ? team : me.team)) || Array.from(this.permissions.readwrite).includes((team != null ? team : me.team));
    }

    canWrite(team) {
      return Array.from(this.permissions.readwrite).includes((team != null ? team : me.team));
    }

    getSource() {
      let left;
      return (left = (this.view != null ? this.view.getSource() : undefined)) != null ? left : this.source;
    }

    transpile(source) {
      if (source) {
        this.source = source;
      } else {
        source = this.getSource();
      }
      if (this.language !== 'html') {
        if (this.thang != null) {
          this.thang.aether.transpile(source);
        }
        this.session.lastAST = this.thang != null ? this.thang.aether.ast : undefined;
      }
      return null;
    }

    // NOTE: By default, I think this compares the current source code with the source *last saved to the server* (not the last time it was run)
    hasChanged(newSource=null, currentSource=null) {
      return (newSource != null ? newSource : this.originalSource) !== (currentSource != null ? currentSource : this.source);
    }

    hasChangedSignificantly(newSource=null, currentSource=null, cb) {
      let aether;
      if (!(aether = this.thang != null ? this.thang.aether : undefined)) {
        console.error(this.toString(), 'couldn\'t find a spellThang with aether', this.thang);
        cb(false);
      }
      if (this.worker) {
        const workerMessage = {
          function: 'hasChangedSignificantly',
          a: (newSource != null ? newSource : this.originalSource),
          spellKey: this.spellKey,
          b: (currentSource != null ? currentSource : this.source),
          careAboutLineNumbers: true,
          careAboutLint: true
        };
        const workerDataCb = function (e) {
          const workerData = JSON.parse(e.data)
          if ((workerData.function === 'hasChangedSignificantly') && (workerData.spellKey === this.spellKey)) {
            this.worker.removeEventListener('message', workerDataCb, false)
            return cb(workerData.hasChanged);
          }
        }
        this.worker.addEventListener('message', workerDataCb, false)
        return this.worker.postMessage(JSON.stringify(workerMessage));
      } else {
        return cb(aether.hasChangedSignificantly((newSource != null ? newSource : this.originalSource), (currentSource != null ? currentSource : this.source), true, true));
      }
    }

    createAether(thang) {
      const writable = (this.permissions.readwrite.length > 0) && !this.isAISource;
      const skipProtectAPI = this.skipProtectAPI || !writable || this.level.isType('game-dev');
      const problemContext = this.createProblemContext(thang);
      const includeFlow = this.level.isType('hero', 'hero-ladder', 'hero-coop', 'course', 'course-ladder', 'game-dev', 'ladder') && !skipProtectAPI;
      const aetherOptions = createAetherOptions({
        functionName: this.name,
        codeLanguage: this.language,
        functionParameters: this.parameters,
        skipProtectAPI,
        includeFlow,
        problemContext,
        useInterpreter: true
      });
      const aether = new Aether(aetherOptions);
      if (this.worker) {
        const workerMessage = {
          function: 'createAether',
          spellKey: this.spellKey,
          options: aetherOptions
        };
        this.worker.postMessage(JSON.stringify(workerMessage));
      }
      return aether;
    }

    updateLanguageAether(language) {
      this.language = language;
      __guard__(this.thang != null ? this.thang.aether : undefined, x => x.setLanguage(this.language));
      if (this.thang) {
        this.thang.castAether = null;
      }
      Backbone.Mediator.publish('tome:spell-changed-language', {spell: this, language: this.language});
      if (this.worker) {
        const workerMessage = {
          function: 'updateLanguageAether',
          newLanguage: this.language
        };
        this.worker.postMessage(JSON.stringify(workerMessage));
      }
      return this.transpile();
    }

    toString() {
      return `<Spell: ${this.spellKey}>`;
    }

    createProblemContext(thang) {
      // Create problemContext Aether can use to craft better error messages
      // stringReferences: values that should be referred to as a string instead of a variable (e.g. "Brak", not Brak)
      // thisMethods: methods available on the 'this' object
      // thisProperties: properties available on the 'this' object
      // commonThisMethods: methods that are available sometimes, but not awlays

      // NOTE: Assuming the first createProblemContext call has everything we need, and we'll use that forevermore
      if (this.problemContext != null) { return this.problemContext; }

      this.problemContext = { stringReferences: [], thisMethods: [], thisProperties: [] };
      // TODO: These should be read from the database
      this.problemContext.commonThisMethods = ['moveRight', 'moveLeft', 'moveUp', 'moveDown', 'attack', 'findNearestEnemy', 'buildXY', 'moveXY', 'say', 'move', 'distance', 'findEnemies', 'findFriends', 'addFlag', 'findFlag', 'removeFlag', 'findFlags', 'attackRange', 'cast', 'buildTypes', 'jump', 'jumpTo', 'attackXY'];
      if (thang == null) { return this.problemContext; }

      // Populate stringReferences
      for (var key in (thang.world != null ? thang.world.thangMap : undefined)) {
        var value = (thang.world != null ? thang.world.thangMap : undefined)[key];
        if ((value.isAttackable || value.isSelectable) && !Array.from(this.problemContext.stringReferences).includes(value.id)) {
          this.problemContext.stringReferences.push(value.id);
        }
      }

      // Populate thisMethods and thisProperties
      if (thang.programmableProperties != null) {
        for (var prop of Array.from(thang.programmableProperties)) {
          if (_.isFunction(thang[prop])) {
            this.problemContext.thisMethods.push(prop);
          } else {
            this.problemContext.thisProperties.push(prop);
          }
        }
      }

      // TODO: See SpellPaletteView.createPalette() for other interesting contextual properties

      this.problemContext.thisValueAlias = this.level.isType('game-dev') ? 'game' : 'hero';

      return this.problemContext;
    }

    createChatMessageContext(chat) {
      const context = {code: {}};
      if (chat.example) {
        // Add translation info, for generating permutations
        context.codeComments = {context: this.commentContext || {}, i18n: this.commentI18N || {}};
      }

      for (var codeType of ['start', 'solution', 'current']) {
        var codeLanguages;
        context.code[codeType] = {};
        if (chat.example && (this.language === 'javascript')) {
          codeLanguages = ['javascript', 'python', 'coffeescript', 'lua', 'java', 'cpp'];
        } else {
          // TODO: how to handle web dev?
          codeLanguages = [this.language];
        }
        for (var codeLanguage of Array.from(codeLanguages)) {
          var source = (() => { switch (codeType) {
            case 'start': return this.languages[codeLanguage];
            case 'solution': return this.getSolution(codeLanguage);
            case 'current':
              if (codeLanguage === this.language) { return this.source; } else { return ''; }
          } })();
          var jsSource = (() => { switch (codeType) {
            case 'start': return this.languages.javascript;
            case 'solution': return this.getSolution('javascript');
            case 'current':
              if (this.language === 'javascript') { return this.source; } else { return ''; }
          } })();
          if (jsSource && !source) {
            source = translateJS(jsSource, codeLanguage);
          }
          if (!source) { continue; }
          if (codeType === 'current') { // handle cpp/java source
            if (/^\u56E7[a-zA-Z0-9+/=]+\f$/.test(source)) {
              var { Unibabel } = require('unibabel');  // Cannot be imported in Node.js context
              var token = JSON.parse(Unibabel.base64ToUtf8(source.substr(1, source.length-2)));
              source = token.src;
            }
          }
          if (chat.example && (codeType === 'current')) {
            // Try to go backwards from translated string literals to initial comment tags so that we can regenerate those comments in other languages
            source = this.untranslateCommentContext({source, commentContext: this.commentContext, commentI18N: this.commentI18N, spokenLanguage: me.get('preferredLanguage'), codeLanguage});
          }
          if (!chat.example) {
            // Bake the translation in
            source = this.translateCommentContext({source, commentContext: this.commentContext, commentI18N: this.commentI18N, spokenLanguage: me.get('preferredLanguage'), codeLanguage});
          }
          context.code[codeType][codeLanguage] = source;
        }
      }

      return context;
    }

    reloadCode() {
      // We pressed the reload button. Fetch our original source again in case it changed.
      let programmableMethod;
      if (!(programmableMethod = __guard__(__guard__(this.thang != null ? this.thang.thang : undefined, x1 => x1.programmableMethods), x => x[this.name]))) { return; }
      return this.createFromProgrammableMethod(programmableMethod, this.language);
    }
  };
  Spell.initClass();
  return Spell;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}