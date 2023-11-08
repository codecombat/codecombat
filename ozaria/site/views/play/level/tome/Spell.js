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
const {me} = require('core/auth');
const {createAetherOptions} = require('lib/aether_utils');
const utils = require('core/utils');
const store = require('core/store');

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
        this.view = new SpellView({spell: this, level: options.level, session: this.session, otherSession: this.otherSession, worker: this.worker, god: options.god, supermodel: this.supermodel, levelID: options.levelID, courseID: options.courseID, classroomAceConfig: options.classroomAceConfig});
        this.view.render();  // Get it ready and code loaded in advance
      }
      Backbone.Mediator.publish('tome:spell-created', {spell: this});
    }

    createFromProgrammableMethod(programmableMethod, codeLanguage) {
      let sessionSource;
      const p = programmableMethod;
      this.commentI18N = p.i18n;
      this.commentContext = p.context;
      this.languages = p.languages != null ? p.languages : {};
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
      if (this.permissions.readwrite.length && (sessionSource = this.session.getSourceFor(this.spellKey))) {
        if (sessionSource !== '// Should fill in some default source\n') {  // TODO: figure out why session is getting this default source in there and stop it
          this.source = sessionSource;
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
      this.originalSource = this.languages[this.language] != null ? this.languages[this.language] : this.languages.javascript;
      if (window.serverConfig.picoCTF) { this.originalSource = this.addPicoCTFProblem(); }

      if (this.level.isType('web-dev')) {
        // Pull apart the structural wrapper code and the player code, remember the wrapper code, and strip indentation on player code.
        const playerCode = utils.extractPlayerCodeTag(this.originalSource);
        this.wrapperCode = this.originalSource.replace(/<playercode>[\s\S]*<\/playercode>/, '☃');  // ☃ serves as placeholder for constructHTML
        this.originalSource = playerCode;
      }

      // Translate comments chosen spoken language.
      // TODO: is there a better way than hardcoding this template string.
      if (!this.commentContext && !this.originalSource.includes('<%= external_ch1_avatar %>')) { return; }
      let context = $.extend(true, {}, this.commentContext);
      context = _.merge(context, {external_ch1_avatar: (store.getters['me/getCh1Avatar'] != null ? store.getters['me/getCh1Avatar'].avatarCodeString : undefined) || 'crown'} );

      if (this.language === 'lua') {
        for (var k in context) {
          var v = context[k];
          context[k] = v.replace(/\b([a-zA-Z]+)\.([a-zA-Z_]+\()/, '$1:$2');
        }
      }

      if (this.commentI18N) {
        let spokenLanguage = me.get('preferredLanguage');
        while (spokenLanguage) {
          var spokenLanguageContext;
          if (fallingBack != null) { spokenLanguage = spokenLanguage.substr(0, spokenLanguage.lastIndexOf('-')); }
          if (spokenLanguageContext = this.commentI18N[spokenLanguage] != null ? this.commentI18N[spokenLanguage].context : undefined) {
            context = _.merge(context, spokenLanguageContext);
            break;
          }
          var fallingBack = true;
        }
      }
      try {
        this.originalSource = _.template(this.originalSource, context);
        this.wrapperCode = _.template(this.wrapperCode, context);
      } catch (e) {
        console.error("Couldn't create example code template of", this.originalSource, "\nwith context", context, "\nError:", e);
      }

      if (/loop/.test(this.originalSource) && this.level.isType('course', 'course-ladder')) {
        // Temporary hackery to make it look like we meant while True: in our sample code until we can update everything
        return this.originalSource = (() => { switch (this.language) {
          case 'python': return this.originalSource.replace(/loop:/, 'while True:');
          case 'javascript': return this.originalSource.replace(/loop {/, 'while (true) {');
          case 'lua': return this.originalSource.replace(/loop\n/, 'while true then\n');
          case 'coffeescript': return this.originalSource;
          default: return this.originalSource;
        } })();
      }
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
            return cb(workerData.hasChanged)
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
      const includeFlow = this.level.isType('hero', 'hero-ladder', 'hero-coop', 'course', 'course-ladder', 'game-dev') && !skipProtectAPI;
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
      if (this.thang != null) {
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