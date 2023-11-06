// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ThangType;
const CocoModel = require('./CocoModel');
const SpriteBuilder = require('lib/sprites/SpriteBuilder');
const LevelComponent = require('./LevelComponent');
const CocoCollection = require('collections/CocoCollection');
const createjs = require('lib/createjs-parts');
const ThangTypeConstants = require('lib/ThangTypeConstants');
const ThangTypeLib = require('lib/ThangTypeLib');

const utils = require('core/utils');

// This method loads a createjs javascript file, and executes this file.
// @param {string} movieClipUrl - The url of the javascript file.
// @return {Promise<Object>} - The movieclips and metaData returned from the createjs javascript file.
const loadCreateJs = movieClipUrl => fetch(movieClipUrl, { method: "GET" })
  .then(data => data.text())
  .then(function(movieClipDefinition) {
    // There is a method that is deprecated that we need to replace. The method and property are semantically identical
    movieClipDefinition = movieClipDefinition.replace(/getNumChildren\(\)/g, 'numChildren');

    const AnimateComposition = {};
    new Function('createjs', 'AdobeAn', movieClipDefinition)(window.createjs, AnimateComposition);

    if (Object.values(AnimateComposition.compositions).length !== 1) {
      throw new Error('There must be one composition per Adobe Animate export');
    }

    const comp = Object.values(AnimateComposition.compositions)[0];
    const lib = comp.getLibrary();
    const ss = comp.getSpriteSheet();
    const {
      ssMetadata
    } = lib;

    return {
      lib,
      ss,
      ssMetadata
    };
  });


let buildQueue = [];

module.exports = (ThangType = (function() {
  ThangType = class ThangType extends CocoModel {
    constructor(...args) {
      super(...args);
      this.onFileUploaded = this.onFileUploaded.bind(this)
    }

    static initClass() {
      this.className = 'ThangType';
      this.schema = require('schemas/models/thang_type');
      this.heroes = utils.isOzaria ? ThangTypeConstants.ozariaHeroes : ThangTypeConstants.heroes;
      this.heroClasses = ThangTypeConstants.heroClasses;
      this.items = ThangTypeConstants.items;
      this.prototype.urlRoot = '/db/thang.type';
      this.prototype.building = {};
      this.prototype.editableByArtisans = true;
      this.defaultActions = ['idle', 'die', 'move', 'attack', 'trick', 'cast'];
      this.heroConfigStats = {};
        // Build a cache of these for quickly determining hero/item loadout aggregate stats
    }

    initialize() {
      super.initialize();
      this.building = {};
      this.spriteSheets = {};
      if (utils.isOzaria) {
        this.textureAtlases = new Map();

        // Vue recursively traverses objects making them reactive.
        // Our thangs are referenced from a reactive object somewhere in the
        // codebase adding a large performance hit with no functional benefit.
        //
        // This line tricks Vue into thinking it has already made this ThangType
        // reactive.
        return Vue.nonreactive(this);
      }
    }

      //# Testing memory clearing
      //f = =>
      //  console.info 'resetting raw data'
      //  @unset 'raw'
      //  @_previousAttributes.raw = null
      //setTimeout f, 40000

    destroy() {
      __guardMethod__(this.rasterImage, 'off', o => o.off());
      return super.destroy();
    }

    resetRawData() {
      return this.set('raw', {shapes: {}, containers: {}, animations: {}});
    }

    resetSpriteSheetCache() {
      this.buildActions();
      this.spriteSheets = {};
      return this.building = {};
    }

    isFullyLoaded() {
      // TODO: Come up with a better way to identify when the model doesn't have everything needed to build the sprite. ie when it's a projection without all the required data.
      return this.get('actions') || this.get('raster'); // needs one of these two things
    }

    loadRasterImage() {
      let raster;
      if (this.loadingRaster || this.loadedRaster) { return; }
      if (!(raster = this.get('raster'))) { return; }
      if (utils.isOzaria) {
        this.rasterImage = $(`<img crossOrigin='Anonymous' src='/file/${raster}' />`);
      } else {
        // IE11 does not support CORS for images in the canvas element
        // https://caniuse.com/#feat=cors
        this.rasterImage = utils.isIE() ? $(`<img src='/file/${raster}' />`)
        : $(`<img crossOrigin='Anonymous', src='/file/${raster}' />`);
      }
      this.loadingRaster = true;
      this.rasterImage.one('load', () => {
        this.loadingRaster = false;
        this.loadedRaster = true;
        this.trigger('raster-image-loaded', this);
        return this.rasterImage.off('error');
      });
      return this.rasterImage.one('error', error => {
        if (error) {
          console.log('Raster image error', error);
        }
        this.loadingRaster = false;
        console.log('Raster image error', this);
        this.trigger('raster-image-load-errored', this);
        return this.rasterImage.off('load');
      });
    }

    getActions() {
      if (!this.isFullyLoaded()) { return {}; }
      return this.actions || this.buildActions();
    }

    getDefaultActions() {
      const actions = [];
      for (var action of Array.from(_.values(this.getActions()))) {
        if (!_.any(ThangType.defaultActions, prefix => _.string.startsWith(action.name, prefix))) { continue; }
        actions.push(action);
      }
      return actions;
    }

    buildActions() {
      if (!this.isFullyLoaded()) { return null; }
      this.actions = $.extend(true, {}, this.get('actions'));
      for (var name in this.actions) {
        var action = this.actions[name];
        action.name = name;
        var object = action.relatedActions != null ? action.relatedActions : {};
        for (var relatedName in object) {
          var relatedAction = object[relatedName];
          relatedAction.name = action.name + '_' + relatedName;
          this.actions[relatedAction.name] = relatedAction;
        }
      }
      return this.actions;
    }

    fillOptions(options) {
      if (options == null) { options = {}; }
      options = _.clone(options);
      if (options.resolutionFactor == null) { options.resolutionFactor = SPRITE_RESOLUTION_FACTOR; }
      if (options.async == null) { options.async = false; }
      options.thang = null;  // Don't hold onto any bad Thang references.
      return options;
    }

    buildSpriteSheet(options) {
      let ss;
      if (!this.isFullyLoaded() || !this.get('raw')) { return false; }
      this.options = this.fillOptions(options);
      const key = this.spriteSheetKey(this.options);
      if (ss = this.spriteSheets[key]) { return ss; }
      if (this.building[key]) {
        this.options = null;
        return key;
      }
      this.t0 = new Date().getTime();
      this.initBuild(options);
      if (!this.options.portraitOnly) { this.addGeneralFrames(); }
      this.addPortrait();
      this.building[key] = true;
      const result = this.finishBuild();
      return result;
    }

    initBuild(options) {
      if (!this.actions) { this.buildActions(); }
      this.vectorParser = new SpriteBuilder(this, options);
      this.builder = new createjs.SpriteSheetBuilder();
      this.builder.padding = 2;
      return this.frames = {};
    }

    addPortrait() {
      // The portrait is built very differently than the other animations, so it gets a separate function.
      if (!this.actions) { return; }
      const {
        portrait
      } = this.actions;
      if (!portrait) { return; }
      const scale = portrait.scale || 1;
      const pt = portrait.positions != null ? portrait.positions.registration : undefined;
      const rect = new createjs.Rectangle(((pt != null ? pt.x : undefined)/scale) || 0, ((pt != null ? pt.y : undefined)/scale) || 0, 100/scale, 100/scale);
      if (portrait.animation) {
        const mc = this.vectorParser.buildMovieClip(portrait.animation);
        mc.nominalBounds = (mc.frameBounds = null); // override what the movie clip says on bounding
        this.builder.addMovieClip(mc, rect, scale);
        let {
          frames
        } = this.builder._animations[portrait.animation];
        if (portrait.frames != null) { frames = this.mapFrames(portrait.frames, frames[0]); }
        return this.builder.addAnimation('portrait', frames, true);
      } else if (portrait.container) {
        const s = this.vectorParser.buildContainerFromStore(portrait.container);
        const frame = this.builder.addFrame(s, rect, scale);
        return this.builder.addAnimation('portrait', [frame], false);
      }
    }

    addGeneralFrames() {
      let action, animation, name, scale;
      const framesMap = {};
      for (animation of Array.from(this.requiredRawAnimations())) {
        name = animation.animation;
        var mc = this.vectorParser.buildMovieClip(name);
        if (!mc) { continue; }
        this.builder.addMovieClip(mc, null, animation.scale * this.options.resolutionFactor);
        framesMap[animation.scale + '_' + name] = this.builder._animations[name].frames;
      }

      for (name in this.actions) {
        action = this.actions[name];
        if (action.animation) {var left;

          if (name === 'portrait') { continue; }
          scale = (left = action.scale != null ? action.scale : this.get('scale')) != null ? left : 1;
          var frames = framesMap[scale + '_' + action.animation];
          if (!frames) { continue; }
          if (action.frames != null) { frames = this.mapFrames(action.frames, frames[0]); }
          var next = true;
          if (action.goesTo) { next = action.goesTo; }
          if (action.loops === false) { next = false; }
          this.builder.addAnimation(name, frames, next);
        }
      }

      return (() => {
        const result = [];
        for (name in this.actions) {
          action = this.actions[name];
          if (action.container && !action.animation) {
            if (name === 'portrait') { continue; }
            scale = this.options.resolutionFactor * (action.scale || this.get('scale') || 1);
            var s = this.vectorParser.buildContainerFromStore(action.container);
            if (!s) { continue; }
            var frame = this.builder.addFrame(s, s.bounds, scale);
            result.push(this.builder.addAnimation(name, [frame], false));
          }
        }
        return result;
      })();
    }

    requiredRawAnimations() {
      const required = [];
      const object = this.get('actions');
      for (var name in object) {
        var action = object[name];
        if (name === 'portrait') { continue; }
        var allActions = [action].concat(_.values((action.relatedActions != null ? action.relatedActions : {})));
        for (var a of Array.from(allActions)) {
          if (a.animation) {
            var scale = name === 'portrait' ? a.scale || 1 : a.scale || this.get('scale') || 1;
            var animation = {animation: a.animation, scale};
            animation.portrait = name === 'portrait';
            if (!_.find(required, r => _.isEqual(r, animation))) {
              required.push(animation);
            }
          }
        }
      }
      return required;
    }

    mapFrames(frames, frameOffset) {
      if (!_.isString(frames)) { return frames; } // don't accidentally do this again
      return (Array.from(frames.split(',')).map((f) => parseInt(f, 10) + frameOffset));
    }

    finishBuild() {
      if (_.isEmpty(this.builder._animations)) { return; }
      const key = this.spriteSheetKey(this.options);
      let spriteSheet = null;
      if (this.options.async) {
        buildQueue.push(this.builder);
        this.builder.t0 = new Date().getTime();
        if (!(buildQueue.length > 1)) { this.builder.buildAsync(); }
        this.builder.on('complete', this.onBuildSpriteSheetComplete, this, true, [this.builder, key, this.options]);
        this.builder = null;
        return key;
      }
      spriteSheet = this.builder.build();
      this.logBuild(this.t0, false, this.options.portraitOnly);
      this.spriteSheets[key] = spriteSheet;
      this.building[key] = false;
      this.builder = null;
      this.options = null;
      return spriteSheet;
    }

    onBuildSpriteSheetComplete(e, data) {
      const [builder, key, options] = Array.from(data);
      this.logBuild(builder.t0, true, options.portraitOnly);
      buildQueue = buildQueue.slice(1);
      if (buildQueue[0]) { buildQueue[0].t0 = new Date().getTime(); }
      if (buildQueue[0] != null) {
        buildQueue[0].buildAsync();
      }
      this.spriteSheets[key] = e.target.spriteSheet;
      this.building[key] = false;
      this.trigger('build-complete', {key, thangType: this});
      return this.vectorParser = null;
    }

    logBuild(startTime, async, portrait) {
      const kind = async ? 'Async' : 'Sync ';
      portrait = portrait ? '(Portrait)' : '';
      const name = _.string.rpad(this.get('name'), 20);
      const time = _.string.lpad(('' + new Date().getTime()) - startTime, 6);
      return console.debug(`Built sheet:  ${name} ${time}ms  ${kind}  ${portrait}`);
    }

    spriteSheetKey(options) {
      let colorConfigs = [];
      const object = options.colorConfig || {};
      for (var groupName in object) {
        var config = object[groupName];
        colorConfigs.push(`${groupName}:${config.hue}|${config.saturation}|${config.lightness}`);
      }
      colorConfigs = colorConfigs.join(',');
      const portraitOnly = !!options.portraitOnly;
      return `${this.get('name')} - ${options.resolutionFactor} - ${colorConfigs} - ${portraitOnly}`;
    }

    getHeroShortName() { return ThangTypeLib.getHeroShortName(this.attributes); }

    getGender() { return ThangTypeLib.getGender(this.attributes); }

    getPortraitImage(spriteOptionsOrKey, size) {
      if (size == null) { size = 100; }
      const src = this.getPortraitSource(spriteOptionsOrKey, size);
      if (!src) { return null; }
      return $('<img />').attr('src', src);
    }

    getPortraitSource(spriteOptionsOrKey, size) {
      if (size == null) { size = 100; }
      if (this.get('rasterIcon') || this.get('raster')) { return this.getPortraitURL(); }
      const stage = this.getPortraitStage(spriteOptionsOrKey, size);
      return (stage != null ? stage.toDataURL() : undefined);
    }

    getPortraitStage(spriteOptionsOrKey, size) {
      let stage;
      if (size == null) { size = 100; }
      const canvas = $(`<canvas width='${size}' height='${size}'></canvas>`);
      try {
        stage = new createjs.Stage(canvas[0]);
      } catch (err) {
        console.error(`Error trying to create ${this.get('name')} avatar stage:`, err, "with window as", window);
        return null;
      }
      if (!this.isFullyLoaded()) { return stage; }
      let key = spriteOptionsOrKey;
      key = _.isString(key) ? key : this.spriteSheetKey(this.fillOptions(key));
      let spriteSheet = this.spriteSheets[key];
      if (!spriteSheet) {
        const options = _.isPlainObject(spriteOptionsOrKey) ? spriteOptionsOrKey : {};
        options.portraitOnly = true;
        spriteSheet = this.buildSpriteSheet(options);
      }
      if (_.isString(spriteSheet)) { return; }
      if (!spriteSheet) { return; }
      const sprite = new createjs.Sprite(spriteSheet);
      const pt = __guard__(this.actions.portrait != null ? this.actions.portrait.positions : undefined, x => x.registration);
      sprite.regX = (pt != null ? pt.x : undefined) || 0;
      sprite.regY = (pt != null ? pt.y : undefined) || 0;
      sprite.framerate = (this.actions.portrait != null ? this.actions.portrait.framerate : undefined) != null ? (this.actions.portrait != null ? this.actions.portrait.framerate : undefined) : 20;
      sprite.gotoAndStop('portrait');
      stage.addChild(sprite);
      stage.update();
      stage.startTalking = () => sprite.gotoAndPlay('portrait');
      stage.stopTalking = () => sprite.gotoAndStop('portrait');
      return stage;
    }

    getVectorPortraitStage(size) {
      let sprite;
      if (size == null) { size = 100; }
      if (!this.actions) { return; }
      const canvas = $(`<canvas width='${size}' height='${size}'></canvas>`);
      const stage = new createjs.Stage(canvas[0]);
      const {
        portrait
      } = this.actions;
      if (!portrait || (!portrait.animation && !portrait.container)) { return; }
      const scale = portrait.scale || 1;

      const vectorParser = new SpriteBuilder(this, {});
      if (portrait.animation) {
        sprite = vectorParser.buildMovieClip(portrait.animation);
        sprite.gotoAndStop(0);
      } else if (portrait.container) {
        sprite = vectorParser.buildContainerFromStore(portrait.container);
      }

      const pt = portrait.positions != null ? portrait.positions.registration : undefined;
      sprite.regX = ((pt != null ? pt.x : undefined) / scale) || 0;
      sprite.regY = ((pt != null ? pt.y : undefined) / scale) || 0;
      sprite.scaleX = (sprite.scaleY = (scale * size) / 100);
      stage.addChild(sprite);
      stage.update();
      return stage;
    }

    uploadGenericPortrait(callback, src) {
      if (src == null) { src = this.getPortraitSource(); }
      if (!src || !_.string.startsWith(src, 'data:')) { return (typeof callback === 'function' ? callback() : undefined); }
      src = src.replace('data:image/png;base64,', '').replace(/\ /g, '+');
      const body = {
        filename: 'portrait.png',
        mimetype: 'image/png',
        path: `db/thang.type/${this.get('original')}`,
        b64png: src,
        force: 'true'
      };
      return $.ajax('/file', {type: 'POST', data: body, success: callback || this.onFileUploaded});
    }

    onFileUploaded() {
      return console.log('Image uploaded');
    }

    static loadUniversalWizard() {
      if (this.wizardType) { return this.wizardType; }
      const wizOriginal = '52a00d55cf1818f2be00000b';
      const url = `/db/thang.type/${wizOriginal}/version`;
      this.wizardType = new module.exports();
      this.wizardType.url = () => url;
      this.wizardType.fetch();
      return this.wizardType;
    }

    getPortraitURL() { return ThangTypeLib.getPortraitURL(this.attributes); }

    // Item functions

    getAllowedSlots() {
      const itemComponentRef = _.find(
        this.get('components') || [],
        compRef => compRef.original === LevelComponent.ItemID);
      return __guard__(itemComponentRef != null ? itemComponentRef.config : undefined, x => x.slots) || ['right-hand'];  // ['right-hand'] is default
    }

    getAllowedHeroClasses() {
      let heroClass;
      if (heroClass = this.get('heroClass')) { return [heroClass]; }
      return ['Warrior', 'Ranger', 'Wizard'];
    }

    getHeroStats() {
      // Translate from raw hero properties into appropriate display values for the PlayHeroesModal.
      // Adapted from https://docs.google.com/a/codecombat.com/spreadsheets/d/1BGI1bzT4xHvWA81aeyIaCKWWw9zxn7-MwDdydmB5vw4/edit#gid=809922675
      let equipsConfig, heroClass, movesConfig;
      if (!(heroClass = this.get('heroClass'))) { return; }
      const components = this.get('components') || [];
      if (!(equipsConfig = __guard__(_.find(components, {original: LevelComponent.EquipsID}), x => x.config))) {
        return console.warn(this.get('name'), 'is not an equipping hero, but you are asking for its hero stats. (Did you project away components?)');
      }
      if (!(movesConfig = __guard__(_.find(components, {original: LevelComponent.MovesID}), x1 => x1.config))) {
        return console.warn(this.get('name'), 'is not a moving hero, but you are asking for its hero stats.');
      }
      let programmableConfig = __guard__(_.find(components, {original: LevelComponent.ProgrammableID}), x2 => x2.config);
      if (utils.isOzaria) {
        programmableConfig = __guard__(_.find(components, c => Array.from(LevelComponent.ProgrammableIDs).includes(c.original)), x3 => x3.config);
      }
      if (!programmableConfig) {
        return console.warn(this.get('name'), 'is not a Programmable hero, but you are asking for its hero stats.');
      }
      if (this.classStatAverages == null) { this.classStatAverages = {
        attack: {Warrior: 7.5, Ranger: 5, Wizard: 2.5},
        health: {Warrior: 7.5, Ranger: 5, Wizard: 3.5}
      }; }
      const stats = {};
      const rawNumbers = {attack: equipsConfig.attackDamageFactor != null ? equipsConfig.attackDamageFactor : 1, health: equipsConfig.maxHealthFactor != null ? equipsConfig.maxHealthFactor : 1, speed: movesConfig.maxSpeed};
      for (var prop of ['attack', 'health']) {
        var classSpecificScore;
        var stat = rawNumbers[prop];
        if (stat < 1) {
          classSpecificScore = 10 - (5 / stat);
        } else {
          classSpecificScore = stat * 5;
        }
        var classAverage = this.classStatAverages[prop][this.get('heroClass')];
        stats[prop] = {
          relative: Math.round(2 * ((classAverage - 2.5) + (classSpecificScore / 2))) / 2 / 10,
          absolute: stat
        };
        var pieces = ([1, 2, 3].map((num) => $.i18n.t(`choose_hero.${prop}_${num}`)));
        var percent = Math.round(stat * 100) + '%';
        var className = $.i18n.t(`general.${_.string.slugify(this.get('heroClass'))}`);
        stats[prop].description = [pieces[0], percent, pieces[1], className, pieces[2]].join(' ');
      }

      const minSpeed = 4;
      const maxSpeed = 16;
      const speedRange = maxSpeed - minSpeed;
      const speedPoints = rawNumbers.speed - minSpeed;
      stats.speed = {
        relative: Math.round((20 * speedPoints) / speedRange) / 2 / 10,
        absolute: rawNumbers.speed,
        description: `${$.i18n.t('choose_hero.speed_1')} ${rawNumbers.speed} ${$.i18n.t('choose_hero.speed_2')}`
      };

      stats.skills = ((() => {
        const result = [];
        for (var skill of Array.from(programmableConfig.programmableProperties)) {           if ((skill !== 'say') && !/(Range|Pos|Radius|Damage)$/.test(skill)) {
            result.push(_.string.titleize(_.string.humanize(skill)));
          }
        }
        return result;
      })());

      return stats;
    }

    getFrontFacingStats() {
      let itemConfig, stat, value;
      const components = this.get('components') || [];
      if (!(itemConfig = __guard__(_.find(components, {original: LevelComponent.ItemID}), x => x.config))) {
        console.warn(this.get('name'), 'is not an item, but you are asking for its stats.');
        return {props: [], stats: {}};
      }
      const stats = {};
      let props = itemConfig.programmableProperties != null ? itemConfig.programmableProperties : [];
      props = props.concat(itemConfig.moreProgrammableProperties != null ? itemConfig.moreProgrammableProperties : []);
      props = _.without(props, 'canCast', 'spellNames', 'spells');
      const object = itemConfig.stats != null ? itemConfig.stats : {};
      for (stat in object) {
        var modifiers = object[stat];
        stats[stat] = this.formatStatDisplay(stat, modifiers);
      }
      for (stat of Array.from(itemConfig.extraHUDProperties != null ? itemConfig.extraHUDProperties : [])) {
        if (stats[stat] == null) { stats[stat] = null; }
      }  // Find it in the other Components.
      for (var component of Array.from(components)) {
        var config;
        if (!(config = component.config)) { continue; }
        for (stat in stats) {
          value = stats[stat];
          if ((value == null)) {
            value = config[stat];
            if (value == null) { continue; }
            stats[stat] = this.formatStatDisplay(stat, {setTo: value});
            if (stat === 'attackDamage') {
              var dps = (value / (config.cooldown || 0.5)).toFixed(1);
              stats[stat].display += ` (${dps} DPS)`;
            }
          }
        }
        if (config.programmableSnippets) {
          props = props.concat(config.programmableSnippets);
        }
      }
      for (stat in stats) {
        value = stats[stat];
        if ((value == null)) {
          stats[stat] = {name: stat, display: '???'};
        }
      }
      const statKeys = _.keys(stats);
      statKeys.sort();
      props.sort();
      const sortedStats = {};
      for (var key of Array.from(statKeys)) { sortedStats[key] = stats[key]; }
      return {props, stats: sortedStats};
    }

    formatStatDisplay(name, modifiers) {
      let matchedShortName;
      const i18nKey = {
        maxHealth: 'health',
        maxSpeed: 'speed',
        healthReplenishRate: 'regeneration',
        attackDamage: 'attack',
        attackRange: 'range',
        shieldDefenseFactor: 'blocks',
        visualRange: 'range',
        throwDamage: 'attack',
        throwRange: 'range',
        bashDamage: 'attack',
        backstabDamage: 'backstab'
      }[name];

      if (i18nKey) {
        name = $.i18n.t('choose_hero.' + i18nKey);
        matchedShortName = true;
      } else {
        name = _.string.humanize(name);
        matchedShortName = false;
      }

      let format = '';
      if (/(range|radius|distance|vision)$/i.test(name)) { format = 'm'; }
      if (/cooldown$/i.test(name)) { if (!format) { format = 's'; } }
      if (/speed$/i.test(name)) { if (!format) { format = 'm/s'; } }
      if (/(regeneration| rate)$/i.test(name)) { if (!format) { format = '/s'; } }
      let value = modifiers.setTo;
      if (/(blocks)$/i.test(name)) {
        if (!format) { format = '%'; }
        value = (value*100).toFixed(1);
      }
      if (_.isArray(value)) { value = value.join(', '); }
      let display = [];
      if (value != null) { display.push(`${value}${format}`); }
      if (modifiers.addend > 0) { display.push(`+${modifiers.addend}${format}`); }
      if (modifiers.addend < 0) { display.push(`${modifiers.addend}${format}`); }
      if ((modifiers.factor != null) && (modifiers.factor !== 1)) { display.push(`x${modifiers.factor}`); }
      display = display.join(', ');
      display = display.replace(/9001m?/, 'Infinity');
      return {name, display, matchedShortName};
    }

    isSilhouettedItem() {
      if ((this.get('gems') == null) && (this.get('tier') == null)) { return console.error(`Trying to determine whether ${this.get('name')} should be a silhouetted item, but it has no gem cost.`); }
      if (this.get('tier') == null) { console.info(`Add (or make sure you have fetched) a tier for ${this.get('name')} to more accurately determine whether it is silhouetted.`); }
      const tier = this.get('tier');
      if (tier != null) {
        return this.levelRequiredForItem() > me.level();
      }
      const points = me.get('points');
      const expectedTotalGems = (points != null ? points : 0) * 1.5;   // Not actually true, but roughly kinda close for tier 0, kinda tier 1
      return this.get('gems') > ((100 + expectedTotalGems) * 1.2);
    }

    levelRequiredForItem() {
      if (this.get('tier') == null) { return console.error(`Trying to determine what level is required for ${this.get('name')}, but it has no tier.`); }
      const itemTier = this.get('tier');
      const playerTier = itemTier / 2.5;
      const playerLevel = me.constructor.levelForTier(playerTier);
      //console.log 'Level required for', @get('name'), 'is', playerLevel, 'player tier', playerTier, 'because it is itemTier', itemTier, 'which is normally level', me.constructor.levelForTier(itemTier)
      return playerLevel;
    }

    getContainersForAnimation(animation, action) {
      const rawAnimation = this.get('raw').animations[animation];
      if (!rawAnimation) {
        console.error('thang type', this.get('name'), 'is missing animation', animation, 'from action', action);
      }
      let {
        containers
      } = rawAnimation;
      for (animation of Array.from(this.get('raw').animations[animation].animations)) {
        containers = containers.concat(this.getContainersForAnimation(animation.gn, action));
      }
      return containers;
    }

    getContainersForActions(actionNames) {
      const containersToRender = {};
      const actions = this.getActions();
      for (var actionName of Array.from(actionNames)) {
        var action = _.find(actions, {name: actionName});
        if (action.container) {
          containersToRender[action.container] = true;
        } else if (action.animation) {
          var animationContainers = this.getContainersForAnimation(action.animation, action);
          for (var container of Array.from(animationContainers)) { containersToRender[container.gn] = true; }
        }
      }
      return _.keys(containersToRender);
    }

    nextForAction(action) {
      let next = true;
      if (action.goesTo) { next = action.goesTo; }
      if (action.loops === false) { next = false; }
      return next;
    }

    noRawData() { return !this.get('raw'); }

    initPrerenderedSpriteSheets() {
      let data;
      if (this.prerenderedSpriteSheets || !(data = this.get('prerenderedSpriteSheetData'))) { return; }
      // creates a collection of prerendered sprite sheets
      return this.prerenderedSpriteSheets = new PrerenderedSpriteSheets(data);
    }

    getPrerenderedSpriteSheet(colorConfig, defaultSpriteType) {
      if (!this.prerenderedSpriteSheets) { return; }
      const spriteType = this.get('spriteType') || defaultSpriteType;
      const result = this.prerenderedSpriteSheets.find(function(pss) {
        if (pss.get('spriteType') !== spriteType) { return false; }
        const otherColorConfig = pss.get('colorConfig');
        if (_.isEmpty(colorConfig) && _.isEmpty(otherColorConfig)) { return true; }
        const getHue = config => _.result(_.result(config, 'team'), 'hue');
        return getHue(colorConfig) === getHue(otherColorConfig);
      });
      if ((!result) && this.noRawData()) {
        return this.prerenderedSpriteSheets.first(); // there can only be one
      }
      return result;
    }

    getPrerenderedSpriteSheetToLoad() {
      if (!this.prerenderedSpriteSheets) { return; }
      if (this.noRawData()) {
        return this.prerenderedSpriteSheets.first(); // there can only be one
      }
      return this.prerenderedSpriteSheets.find(pss => pss.needToLoad && !pss.loadedImage);
    }

    loadAllRasterTextureAtlases() {
      if (this.loadingRasterAtlas || this.loadedRasterAtlas) { return; }
      if (!this.get('rasterAtlasAnimations')) { return; }
      this.loadingRasterAtlas = true;
      const keys = Object.keys(this.get('rasterAtlasAnimations'));

      const loadingPromises = keys
        .map(key => _.merge({key}, this.get('rasterAtlasAnimations')[key]))
        .filter(({movieClip, textureAtlases}) => !(movieClip && (textureAtlases > 0)))
        .map(({movieClip, textureAtlases, key}) => {
          const createJsFetch = loadCreateJs(`/file/${movieClip}`);

          const textureAtlasImages = textureAtlases
            .map(url => $(`<img crossOrigin='Anonymous', src='/file/${url}' />`))
            .map(tag => {
              return new Promise((resolve, reject) => tag.one('load',() => resolve(tag[0])));
          });

          return Promise.all([createJsFetch].concat(textureAtlasImages))
            .then(result => {
              const {lib, ss, ssMetadata} = result.slice(0, 1)[0];
              const images = result.slice(1);
              return this.textureAtlases.set(key, {lib, ss, ssMetadata, images});
            })
            .catch(error => {
              return console.error(`There was an error loading ThangType: '${this.get('name')}':`, error);
            });
        });

      if ((loadingPromises.length || []) >= 1) {
        return Promise.all(loadingPromises)
          .then(() => {
            this.loadedRasterAtlas = true;
            this.loadingRasterAtlas = false;
            return this.trigger('texture-atlas-loaded');
          })
          .catch(error => {
            return console.error('Error loading all ThangType raster animations:', error);
          });
      }
    }

    // Returns the sprite data parsed from the adobe animate's texture-atlas export
    getRasterAtlasSpriteData(action) {
      // TODO: Doesn't construct new movieclip definitions and thus all returned `ss`
      //       objects are the same references.
      let animation = __guard__(this.get('actions')[action], x => x.animation);
      const split_index = action.indexOf('_');
      if (!animation && (split_index !== -1)) {
        let relatedAction;
        [action, relatedAction] = Array.from([action.slice(0, split_index), action.slice(split_index + 1)]);
        animation = __guard__(__guard__(this.get('actions')[action], x2 => x2.relatedActions[relatedAction]), x1 => x1.animation);
      }
      if (!animation) {
        console.warn(`action '${action}' doesn't have an animation defined...`);
        return {};
      }
      if (!this.textureAtlases.get(animation) || (!(this.textureAtlases.get(animation).length || []) > 1)) {
        console.warn(`animation '${animation}' not loaded or doesn't exist...`);
        return {};
      }

      let {lib, ss, ssMetadata, images} = this.textureAtlases.get(animation);

      // Add images to ssMetadata
      ssMetadata = ssMetadata.map(metadata => {
        const img_index = images.map(img => img.src)
          .map(img_src => img_src.split('/').pop())
          .map(img_name => img_name.slice(0,-4))
          .indexOf(encodeURIComponent(metadata.name));
        metadata.images = [images[img_index]];
        return metadata;
      });

      const movieClipInstanceName = this.get('rasterAtlasAnimations')[animation].movieClipName;
      if (!lib[movieClipInstanceName]) {
        throw new Error(`Can't find movieclip called '${movieClipInstanceName}' in javascript file...`);
      }
      return { ssMetadata, ss, movieClip: lib[movieClipInstanceName] };
    }


    onLoaded() {
      let equipsConfig, itemConfig, speed;
      super.onLoaded();
      if (ThangType.heroConfigStats[this.get('original')]) { return; }
      // Cache certain component properties for quickly determining hero/item loadout aggregate stats
      const components = this.get('components') || [];
      if (!components.length) { return; }
      if ((this.get('gems') == null) && (
        (this.project && !/gems/.test(this.project)) ||
        (/project/.test(this.getURL()) && !/gems/.test(this.getURL())) ||
        ((this.collection != null ? this.collection.project : undefined) && !/gems/.test(this.collection != null ? this.collection.project : undefined)) ||
        (/project/.test(this.collection != null ? this.collection.getURL() : undefined) && !/gems/.test(this.collection != null ? this.collection.getURL() : undefined))
      )) { return; }
      const stats = {gems: this.get('gems') || 0};
      if (itemConfig = __guard__(_.find(components, {original: LevelComponent.ItemID}), x => x.config)) {
        let attacksConfig, health;
        stats.kind = 'item';
        if (speed = __guard__(itemConfig.stats != null ? itemConfig.stats.maxSpeed : undefined, x1 => x1.addend)) { stats.speed = speed; }
        if (health = __guard__(itemConfig.stats != null ? itemConfig.stats.maxHealth : undefined, x2 => x2.addend)) { stats.health = health; }
        if (attacksConfig = __guard__(_.find(components, {original: LevelComponent.AttacksID}), x3 => x3.config)) {
          stats.attack = (attacksConfig.attackDamage != null ? attacksConfig.attackDamage : 3) / (attacksConfig.cooldown != null ? attacksConfig.cooldown : 1);
        }
        ThangType.heroConfigStats[this.get('original')] = stats;
      } else if (equipsConfig = __guard__(_.find(components, {original: LevelComponent.EquipsID}), x4 => x4.config)) {
        let attackableConfig, movesConfig;
        stats.kind = 'hero';
        stats.attackMultiplier = equipsConfig.attackDamageFactor != null ? equipsConfig.attackDamageFactor : 1;
        stats.healthMultiplier = equipsConfig.maxHealthFactor != null ? equipsConfig.maxHealthFactor : 1;
        if (movesConfig = __guard__(_.find(components, {original: LevelComponent.MovesID}), x5 => x5.config)) {
          stats.speed = movesConfig.maxSpeed != null ? movesConfig.maxSpeed : 3.6;
        }
        if (attackableConfig = __guard__(_.find(components, {original: LevelComponent.AttackableID}), x6 => x6.config)) {
          stats.baseHealth = attackableConfig.maxHealth != null ? attackableConfig.maxHealth : 11;
        }
        ThangType.heroConfigStats[this.get('original')] = stats;
      }
      return null;
    }

    static calculateStatsForHeroConfig(heroConfig, callback) {
      // Load enough information from the ThangTypes involved in a hero configuration to show various stats the hero will have.
      // We don't rely on any supermodel caches, because this ThangType projection is useless anywhere else.
      let original;
      const thisHeroConfigStats = {};
      const heroOriginal = utils.isOzaria ? ThangType.heroes['hero-b'] : heroConfig.thangType != null ? heroConfig.thangType : ThangType.heroes.captain;
      for (original of Array.from(_.values(heroConfig.inventory).concat([heroOriginal]))) {
        thisHeroConfigStats[original] = ThangType.heroConfigStats[original] || 'loading';
      }
      for (original in thisHeroConfigStats) {
        var stats = thisHeroConfigStats[original];
        if (stats === 'loading') {
          var url = `/db/thang.type/${original}/version?project=original,components,gems`;
          var tt = new ThangType().setURL(url);
          (tt => {
            return tt.on('sync', () => {
              thisHeroConfigStats[tt.get('original')] = ThangType.heroConfigStats[tt.get('original')];
              tt.off('sync');
              tt.destroy();
              return this.formatStatsForHeroConfig(thisHeroConfigStats, callback);
            });
          })(tt);
          tt.fetch();
        }
      }
      return this.formatStatsForHeroConfig(thisHeroConfigStats, callback);
    }

    static formatStatsForHeroConfig(heroConfigStats, callback) {
      const heroConfigStatValues = _.values(heroConfigStats);
      if (Array.from(heroConfigStatValues).includes('loading')) { return; }
      const heroStats = _.find(heroConfigStatValues, {kind: 'hero'});
      const totals = {health: heroStats.baseHealth != null ? heroStats.baseHealth : 11, speed: 0, gems: 0};
      for (var stats of Array.from(heroConfigStatValues)) {
        if (stats.gems) { totals.gems += stats.gems; }
        if (stats.health) { totals.health += stats.health * (heroStats.healthMultiplier || 1); }
        if (stats.attack) { totals.attack = stats.attack * (heroStats.attackMultiplier || 1); }
        if (stats.speed) { totals.speed += stats.speed; }
      }
      return callback(totals);
    }
  };
  ThangType.initClass();
  return ThangType;
})());


class PrerenderedSpriteSheet extends CocoModel {
  static initClass() {
    this.className = 'PrerenderedSpriteSheet';

    this.prototype.needToLoad = false;
    this.prototype.loadedImage = false;
    this.prototype.loadingImage = false;
  }

  loadImage() {
    let imageURL;
    if (this.loadingImage) { return true; }
    if (this.loadedImage) { return false; }
    if (!(imageURL = this.get('image'))) { return false; }
    this.image = $(`<img crossOrigin='Anonymous', src='/file/${imageURL}' />`);
    this.loadingImage = true;
    this.image.one('load', () => {
      this.loadingImage = false;
      this.loadedImage = true;
      this.buildSpriteSheet();
      return this.trigger('image-loaded', this);
  });
    this.image.one('error', () => {
      this.loadingImage = false;
      return this.trigger('image-load-error', this);
    });
    return true;
  }

  buildSpriteSheet() {
    return this.spriteSheet = new createjs.SpriteSheet({
      images: [this.image[0]],
      frames: this.get('frames'),
      animations: this.get('animations')
    });
  }

  markToLoad() { return this.needToLoad = true; }
}
PrerenderedSpriteSheet.initClass();


class PrerenderedSpriteSheets extends CocoCollection {
  static initClass() {
    this.prototype.model = PrerenderedSpriteSheet;
  }
}
PrerenderedSpriteSheets.initClass();

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