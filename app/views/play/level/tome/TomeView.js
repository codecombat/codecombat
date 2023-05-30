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
let TomeView;
require('app/styles/play/level/tome/tome.sass');
// There's one TomeView per Level. It has:
// - a CastButtonView, which has
//   - a cast button
//   - a submit/done button
// - for each spell (programmableMethod) (which is now just always only 'plan')
//   - a Spell, which has
//     - a Thang that uses that Spell, with an aether and a castAether
//     - a SpellView, which has
//       - tons of stuff; the meat
//     - a SpellTopBarView, which has some controls
// - a SpellPaletteView, which has
//   - for each programmableProperty:
//     - a SpellPaletteEntryView
//
// The CastButtonView always shows.
// The SpellPaletteView shows the entries for the currently selected Programmable Thang.
// The SpellView shows the code and runtime state for the currently selected Spell and, specifically, Thang.
// You can switch a SpellView to showing the runtime state of another Thang sharing that Spell.
// SpellPaletteViews are destroyed and recreated whenever you switch Thangs.

const CocoView = require('views/core/CocoView');
const template = require('app/templates/play/level/tome/tome');
const {me} = require('core/auth');
const Spell = require('./Spell');
const SpellPaletteViewBot = require('./SpellPaletteViewBot');
const CastButtonView = require('./CastButtonView');
const utils = require('core/utils');
const store = require('core/store');
const globalVar = require('core/globalVar');

module.exports = (TomeView = (function() {
  TomeView = class TomeView extends CocoView {
    static initClass() {
      this.prototype.id = 'tome-view';
      this.prototype.template = template;
      this.prototype.controlsEnabled = true;
      this.prototype.cache = false;
  
      this.prototype.subscriptions = {
        'tome:spell-loaded': 'onSpellLoaded',
        'tome:cast-spell': 'onCastSpell',
        'tome:change-language': 'updateLanguageForAllSpells',
        'surface:sprite-selected': 'onSpriteSelected',
        'god:new-world-created': 'onNewWorld',
        'tome:comment-my-code': 'onCommentMyCode',
        'tome:reset-my-code': 'onResetMyCode',
        'tome:select-primary-sprite': 'onSelectPrimarySprite'
      };
  
      this.prototype.events =
        {'click': 'onClick'};
    }

    constructor(options) {
      super(options);
      this.unwatchFn = store.watch(
        (state, getters) => getters['game/levelSolution'],
        solution => { if (solution != null ? solution.source : undefined) { return this.onChangeMyCode(solution.source); }
       });
      if (!options.god && (options.level.get('type') !== 'web-dev')) {
        console.error("TomeView created with no God!");
      }
    }

    afterRender() {
      super.afterRender();
      this.worker = this.createWorker();
      let programmableThangs = _.filter(this.options.thangs, t => t.isProgrammable && t.programmableMethods);
      if (this.options.level.isType('web-dev')) {
        if (this.fakeProgrammableThang = this.createFakeProgrammableThang()) {
          programmableThangs = [this.fakeProgrammableThang];
        }
      }
      this.createSpells(programmableThangs, programmableThangs[0] != null ? programmableThangs[0].world : undefined);  // Do before castButton
      this.castButton = this.insertSubView(new CastButtonView({spells: this.spells, level: this.options.level, session: this.options.session, god: this.options.god}));
      this.teamSpellMap = this.generateTeamSpellMap(this.spells);
      if (!programmableThangs.length) {
        this.cast();
        const warning = 'Warning: There are no Programmable Thangs in this level, which makes it unplayable.';
        noty({text: warning, layout: 'topCenter', type: 'warning', killer: false, timeout: 15000, dismissQueue: true, maxVisible: 3});
        console.warn(warning);
      }
      return delete this.options.thangs;
    }

    onNewWorld(e) {
      const programmableThangs = _.filter(e.thangs, t => t.isProgrammable && t.programmableMethods && t.inThangList);
      return this.createSpells(programmableThangs, e.world);
    }

    onCommentMyCode(e) {
      for (var spellKey in this.spells) {
        var spell = this.spells[spellKey];
        if (spell.canWrite()) {
          console.log('Commenting out', spellKey);
          var commentedSource = spell.view.commentOutMyCode() + 'Commented out to stop infinite loop.\n' + spell.getSource();
          spell.view.updateACEText(commentedSource);
          spell.view.recompile(false);
        }
      }
      return _.delay((() => (typeof this.cast === 'function' ? this.cast() : undefined)), 1000);
    }

    onResetMyCode(e) {
      for (var spellKey in this.spells) {
        var spell = this.spells[spellKey];
        if (spell.canWrite()) {
          spell.view.updateACEText(spell.originalSource);
          spell.view.recompile(false);
        }
      }
      return _.delay((() => (typeof this.cast === 'function' ? this.cast() : undefined)), 1000);
    }

    onChangeMyCode(solution) {
      return (() => {
        const result = [];
        for (var spellKey in this.spells) {
          var spell = this.spells[spellKey];
          if (spell.canWrite()) {
            spell.view.updateACEText(solution);
            result.push(spell.view.recompile(false));
          }
        }
        return result;
      })();
    }

    createWorker() {
      if (typeof Worker === 'undefined' || Worker === null) { return null; }
      if (globalVar.application.isIPadApp) { return null; }  // Save memory!
      return new Worker('/javascripts/workers/aether_worker.js');
    }

    generateTeamSpellMap(spellObject) {
      const teamSpellMap = {};
      for (var spellName in spellObject) {
        var spell = spellObject[spellName];
        var teamName = spell.team;
        if (teamSpellMap[teamName] == null) { teamSpellMap[teamName] = []; }

        var spellNameElements = spellName.split('/');
        var thangName = spellNameElements[0];
        spellName = spellNameElements[1];

        if (!Array.from(teamSpellMap[teamName]).includes(thangName)) { teamSpellMap[teamName].push(thangName); }
      }

      return teamSpellMap;
    }

    createSpells(programmableThangs, world) {
      let language, spell, spellKey, thang;
      if (this.options.spectateView) { language = this.options.session.get('submittedCodeLanguage'); }
      if (language == null) { language = this.options.session.get('codeLanguage'); }
      if (language == null) { language = __guard__(me.get('aceConfig'), x => x.language); }
      if (language == null) { language = 'python'; }
      const pathPrefixComponents = ['play', 'level', this.options.levelID, this.options.session.id, 'code'];
      if (this.spells == null) { this.spells = {}; }
      if (this.thangSpells == null) { this.thangSpells = {}; }
      for (thang of Array.from(programmableThangs)) {
        if (this.thangSpells[thang.id] != null) { continue; }
        this.thangSpells[thang.id] = [];
        for (var methodName in thang.programmableMethods) {
          var method = thang.programmableMethods[methodName];
          var pathComponents = [thang.id, methodName];
          pathComponents[0] = _.string.slugify(pathComponents[0]);
          spellKey = pathComponents.join('/');
          this.thangSpells[thang.id].push(spellKey);
          var skipProtectAPI = utils.getQueryVariable('skip_protect_api', false);
          spell = (this.spells[spellKey] = new Spell({
            hintsState: this.options.hintsState,
            programmableMethod: method,
            spellKey,
            pathComponents: pathPrefixComponents.concat(pathComponents),
            session: this.options.session,
            otherSession: this.options.otherSession,
            supermodel: this.supermodel,
            skipProtectAPI,
            worker: this.worker,
            language,
            spectateView: this.options.spectateView,
            observing: this.options.observing,
            levelID: this.options.levelID,
            level: this.options.level,
            god: this.options.god,
            courseID: this.options.courseID,
            courseInstanceID: this.options.courseInstanceID,
            classroomAceConfig: this.options.classroomAceConfig
          }));
        }
      }

      for (var thangID in this.thangSpells) {
        var spellKeys = this.thangSpells[thangID];
        thang = this.fakeProgrammableThang != null ? this.fakeProgrammableThang : world.getThangByID(thangID);
        if (thang) {
          for (spellKey of Array.from(spellKeys)) { this.spells[spellKey].addThang(thang); }
        } else {
          delete this.thangSpells[thangID];
          for (spell of Array.from(this.spells)) { spell.removeThangID(thangID); }
        }
      }
      for (spellKey in this.spells) {  // Make sure these get transpiled (they have no views).
        spell = this.spells[spellKey];
        if (!spell.canRead()) {
          spell.transpile();
          spell.loaded = true;
        }
      }
      return null;
    }

    onSpellLoaded(e) {
      for (var spellID in this.spells) {
        var spell = this.spells[spellID];
        if (!spell.loaded) { return; }
      }
      const justBegin = this.options.level.isType('game-dev');
      return this.cast(false, false, justBegin);
    }

    onCastSpell(e) {
      // A single spell is cast.
      return this.cast(e != null ? e.preload : undefined, e != null ? e.realTime : undefined, e != null ? e.justBegin : undefined, e != null ? e.cinematic : undefined);
    }

    cast(preload, realTime, justBegin, cinematic) {
      var left, left1;
      if (preload == null) { preload = false; }
      if (realTime == null) { realTime = false; }
      if (justBegin == null) { justBegin = false; }
      if (cinematic == null) { cinematic = false; }
      if (this.options.level.isType('web-dev')) { return; }
      const sessionState = (left = this.options.session.get('state')) != null ? left : {};
      if (realTime) {
        var left1;
        sessionState.submissionCount = (sessionState.submissionCount != null ? sessionState.submissionCount : 0) + 1;
        sessionState.flagHistory = _.filter(sessionState.flagHistory != null ? sessionState.flagHistory : [], event => event.team !== ((left1 = this.options.session.get('team')) != null ? left1 : 'humans'));
        if (this.options.level.get('replayable')) { sessionState.lastUnsuccessfulSubmissionTime = new Date(); }
        this.options.session.set('state', sessionState);
      }
      let difficulty = sessionState.difficulty != null ? sessionState.difficulty : 0;
      if (this.options.observing) {
        difficulty = Math.max(0, difficulty - 1);  // Show the difficulty they won, not the next one.
      }
      Backbone.Mediator.publish('level:set-playing', {playing: false});
      return Backbone.Mediator.publish('tome:cast-spells', {
        spells: this.spells,
        preload,
        realTime,
        synchronous: this.options.level.isType('game-dev') && !justBegin,
        justBegin,
        cinematic,
        difficulty,
        submissionCount: sessionState.submissionCount != null ? sessionState.submissionCount : 0,
        flagHistory: sessionState.flagHistory != null ? sessionState.flagHistory : [],
        god: this.options.god,
        fixedSeed: this.options.fixedSeed,
        keyValueDb: (left1 = this.options.session.get('keyValueDb')) != null ? left1 : {}
      });
    }

    onClick(e) {
      if (!$(e.target).parents('.popover').length) { return Backbone.Mediator.publish('tome:focus-editor', {}); }
    }

    onSpriteSelected(e) {
      let needle;
      if (this.spellView && (needle = this.options.level.get('type', true), ['hero', 'hero-ladder', 'hero-coop', 'course', 'course-ladder', 'game-dev', 'web-dev', 'ladder'].includes(needle))) { return; }  // Never deselect the hero in the Tome. TODO: remove entirely, as this is now all level types?
      const spell = this.spellFor(e.thang, e.spellName);
      if (spell != null ? spell.canRead() : undefined) {
        return this.setSpellView(spell, e.thang);
      }
    }

    setSpellView(spell, thang) {
      if (spell.view !== this.spellView) {
        this.spellView = spell.view;
        this.spellTopBarView = spell.topBarView;
        this.$el.find('#' + this.spellView.id).after(this.spellView.el).remove();
        this.$el.find('#' + this.spellTopBarView.id).after(this.spellTopBarView.el).remove();
        if (this.castButton != null) {
          this.castButton.attachTo(this.spellView);
        }
      }
      this.updateSpellPalette(thang, spell);
      return (this.spellView != null ? this.spellView.setThang(thang) : undefined);
    }

    updateSpellPalette(thang, spell) {
      const paletteManagedInParent = this.options.playLevelView != null ? this.options.playLevelView.updateSpellPalette(thang, spell) : undefined;
      this.$('#spell-palette-view-bot').toggleClass('hidden', paletteManagedInParent);
      if (paletteManagedInParent) { return; }
      const useHero = /hero/.test(spell.getSource()) || !/(self[\.\:]|this\.|\@)/.test(spell.getSource());
      if (this.spellPaletteView && !(this.spellPaletteView != null ? this.spellPaletteView.destroyed : undefined)) { this.removeSubView(this.spellPaletteView); }
      this.spellPaletteView = this.insertSubView(new SpellPaletteViewBot({ thang, supermodel: this.supermodel, programmable: (spell != null ? spell.canRead() : undefined), language: (spell != null ? spell.language : undefined) != null ? (spell != null ? spell.language : undefined) : this.options.session.get('codeLanguage'), session: this.options.session, level: this.options.level, courseID: this.options.courseID, courseInstanceID: this.options.courseInstanceID, useHero }));
      if (spell != null ? spell.view : undefined) { return this.spellPaletteView.toggleControls({}, spell.view.controlsEnabled); }
    }

    spellFor(thang, spellName) {
      let spell;
      if (!(thang != null ? thang.isProgrammable : undefined)) { return null; }
      if (!this.thangSpells[thang.id]) { return; }  // Probably in streaming mode, where we don't update until it's done.
      const selectedThangSpells = (Array.from(this.thangSpells[thang.id]).map((spellKey) => this.spells[spellKey]));
      if (spellName) {
        spell = _.find(selectedThangSpells, {name: spellName});
      } else {
        spell = _.find(selectedThangSpells, spell => spell.canWrite());
        if (spell == null) { spell = _.find(selectedThangSpells, spell => spell.canRead()); }
      }
      return spell;
    }

    reloadAllCode() {
      if (utils.getQueryVariable('dev')) {
        __guard__(this.options.playLevelView != null ? this.options.playLevelView.spellPaletteView : undefined, x => x.destroy());
        if (this.spellView) { this.updateSpellPalette(this.spellView.thang, this.spellView.spell); }
      }
      for (var spellKey in this.spells) { var spell = this.spells[spellKey]; if (spell.view && ((spell.team === me.team) || (['common', 'neutral', null].includes(spell.team)))) { spell.view.reloadCode(false); } }
      return this.cast(false, false);
    }

    updateLanguageForAllSpells(e) {
      for (var spellKey in this.spells) { var spell = this.spells[spellKey]; if (spell.canWrite()) { spell.updateLanguageAether(e.language); } }
      if (e.reload) {
        return this.reloadAllCode();
      } else {
        return this.cast();
      }
    }

    onSelectPrimarySprite(e) {
      if (this.options.level.isType('web-dev')) {
        this.setSpellView(this.spells['hero-placeholder/plan'], this.fakeProgrammableThang);
        return;
      }
      // This is fired by PlayLevelView
      if (this.options.session.get('team') === 'ogres') {
        return Backbone.Mediator.publish('level:select-sprite', {thangID: 'Hero Placeholder 1'});
      } else {
        return Backbone.Mediator.publish('level:select-sprite', {thangID: 'Hero Placeholder'});
      }
    }

    createFakeProgrammableThang() {
      let hero, programmableConfig;
      if (!(hero = _.find(this.options.level.get('thangs'), {id: 'Hero Placeholder'}))) { return null; }
      if (!(programmableConfig = _.find(hero.components, component => component.config != null ? component.config.programmableMethods : undefined).config)) { return null; }
      const usesHTMLConfig = _.find(hero.components, component => component.config != null ? component.config.programmableHTMLProperties : undefined).config;
      const usesWebJavaScriptConfig = __guard__(_.find(hero.components, component => component.config != null ? component.config.programmableWebJavaScriptProperties : undefined), x => x.config);
      const usesJQueryConfig = __guard__(_.find(hero.components, component => component.config != null ? component.config.programmableJQueryProperties : undefined), x1 => x1.config);
      if (!usesHTMLConfig) { console.warn("Couldn't find usesHTML config; is it presented and not defaulted on the Hero Placeholder?"); }
      let thang = {
        id: 'Hero Placeholder',
        isProgrammable: true
      };
      thang = _.merge(thang, programmableConfig, usesHTMLConfig, usesWebJavaScriptConfig, usesJQueryConfig);
      return thang;
    }

    destroy() {
      for (var spellKey in this.spells) { var spell = this.spells[spellKey]; spell.destroy(); }
      if (this.worker != null) {
        this.worker.terminate();
      }
      this.unwatchFn();
      return super.destroy();
    }
  };
  TomeView.initClass();
  return TomeView;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}