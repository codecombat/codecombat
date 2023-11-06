// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let LankBoss;
const CocoClass = require('core/CocoClass');
const {me} = require('core/auth');
const LayerAdapter = require('./LayerAdapter');
const FlagLank = require('lib/surface/FlagLank');
const Lank = require('lib/surface/Lank');
const Mark = require('./Mark');
const Grid = require('lib/world/Grid');
const utils = require('core/utils');

module.exports = (LankBoss = (function() {
  LankBoss = class LankBoss extends CocoClass {
    static initClass() {
      this.prototype.subscriptions = {
        'level:set-debug': 'onSetDebug',
        'sprite:highlight-sprites': 'onHighlightSprites',
        'level:select-sprite': 'onSelectSprite',
        'level:suppress-selection-sounds': 'onSuppressSelectionSounds',
        'level:lock-select': 'onSetLockSelect',
        'level:restarted': 'onLevelRestarted',
        'god:new-world-created': 'onNewWorld',
        'god:streaming-world-updated': 'onNewWorld',
        'camera:dragged': 'onCameraDragged',
        'camera:zoom-updated': 'onCameraZoomUpdated',
        'sprite:loaded'() { return this.update(true); },
        'level:flag-color-selected': 'onFlagColorSelected',
        'level:flag-updated': 'onFlagUpdated',
        'surface:flag-appeared': 'onFlagAppeared',
        'surface:remove-selected-flag': 'onRemoveSelectedFlag'
      };
    }

    constructor(options) {
      if (options == null) { options = {}; }
      super();
      this.options = options;
      this.handleEvents = this.options.handleEvents;
      this.gameUIState = this.options.gameUIState;
      this.dragged = 0;
      this.camera = this.options.camera;
      this.webGLStage = this.options.webGLStage;
      this.surfaceTextLayer = this.options.surfaceTextLayer;
      this.world = this.options.world;
      if (this.options.thangTypes == null) { this.options.thangTypes = []; }
      this.lanks = {};
      this.lankArray = [];  // Mirror @lanks, but faster for when we just need to iterate
      this.createLayers();
      this.pendingFlags = [];
      if (!this.handleEvents) {
        this.listenTo(this.gameUIState, 'change:selected', this.onChangeSelected);
      }
    }

    destroy() {
      for (var thangID in this.lanks) { var lank = this.lanks[thangID]; this.removeLank(lank); }
      if (utils.isCodeCombat) {
        if (this.targetMark != null) {
          this.targetMark.destroy();
        }
        if (this.selectionMark != null) {
          this.selectionMark.destroy();
        }
      }
      for (var lankLayer of Array.from(_.values(this.layerAdapters))) { lankLayer.destroy(); }
      return super.destroy();
    }

    toString() { return `<LankBoss: ${this.lankArray.length} lanks>`; }

    thangTypeFor(type) {
      return _.find(this.options.thangTypes, m => (m.get('original') === type) || (m.get('name') === type));
    }

    createLayers() {
      this.layerAdapters = {};
      for (var [name, priority] of [
        ['Land', -40],
        ['Ground', -30],
        ['Obstacle', -20],
        ['Path', -10],
        ['Default', 0],
        ['Floating', 10]
      ]) {
        this.layerAdapters[name] = new LayerAdapter({name, webGL: true, layerPriority: priority, transform: LayerAdapter.TRANSFORM_SURFACE, camera: this.camera});
      }
      return this.webGLStage.addChild(...Array.from(((Array.from(_.values(this.layerAdapters)).map((lankLayer) => lankLayer.container))) || []));
    }

    layerForChild(child, lank) {
      if (child.layerPriority == null) {
        let thang;
        if (thang = lank != null ? lank.thang : undefined) {
          child.layerPriority = thang.layerPriority;
          if (thang.isSelectable) { if (child.layerPriority == null) { child.layerPriority = 0; } }
          if (thang.isLand) { if (child.layerPriority == null) { child.layerPriority = -40; } }
        }
      }
      if (child.layerPriority == null) { child.layerPriority = 0; }
      if (!child.layerPriority) { return this.layerAdapters['Default']; }
      let layer = _.findLast(this.layerAdapters, (layer, name) => layer.layerPriority <= child.layerPriority);
      if (child.layerPriority < -40) { if (layer == null) { layer = this.layerAdapters['Land']; } }
      return layer != null ? layer : this.layerAdapters['Default'];
    }

    addLank(lank, id=null, layer=null) {
      if (id == null) { ({
        id
      } = lank.thang); }
      if (this.lanks[id]) { console.error('Lank collision! Already have:', id); }
      this.lanks[id] = lank;
      this.lankArray.push(lank);
      if ((lank.thang != null ? lank.thang.spriteName.search(/(dungeon|indoor|ice|classroom|vr).wall/i) : undefined) !== -1) { if (layer == null) { layer = this.layerAdapters['Obstacle']; } }
      if (layer == null) { layer = this.layerForChild(lank.sprite, lank); }
      layer.addLank(lank);
      layer.updateLayerOrder();
      return lank;
    }

    createMarks() {
      if (this.world.showTargetMark) {
        this.targetMark = new Mark({name: 'target', camera: this.camera, layer: this.layerAdapters['Ground'], thangType: 'target'});
      }
      return this.selectionMark = new Mark({name: 'selection', camera: this.camera, layer: this.layerAdapters['Ground'], thangType: 'selection'});
    }

    createLankOptions(options) {
      return _.extend(options, {
        camera: this.camera,
        resolutionFactor: SPRITE_RESOLUTION_FACTOR,
        groundLayer: this.layerAdapters['Ground'],
        textLayer: this.surfaceTextLayer,
        floatingLayer: this.layerAdapters['Floating'],
        showInvisible: this.options.showInvisible,
        gameUIState: this.gameUIState,
        handleEvents: this.handleEvents
      });
    }

    onSetDebug(e) {
      if (e.debug === this.debug) { return; }
      this.debug = e.debug;
      return Array.from(this.lankArray).map((lank) => lank.setDebug(this.debug));
    }

    onHighlightSprites(e) {
      const highlightedIDs = e.thangIDs || [];
      return (() => {
        const result = [];
        for (var thangID in this.lanks) {
          var lank = this.lanks[thangID];
          result.push((typeof lank.setHighlight === 'function' ? lank.setHighlight(Array.from(highlightedIDs).includes(thangID), e.delay) : undefined));
        }
        return result;
      })();
    }

    addThangToLanks(thang, layer=null) {
      if (this.lanks[thang.id]) { return console.warn('Tried to add Thang to the surface it already has:', thang.id); }
      let thangType = _.find(this.options.thangTypes, function(m) {
        if (!m.get('actions') && !m.get('raster')) { return false; }
        return m.get('name') === thang.spriteName;
      });
      if (thangType == null) { thangType = _.find(this.options.thangTypes, m => m.get('name') === thang.spriteName); }
      if (!thangType) { return console.error("Couldn't find ThangType for", thang); }

      const options = this.createLankOptions({thang});
      options.resolutionFactor = thangType.get('kind') === 'Floor' ? 2 : SPRITE_RESOLUTION_FACTOR;
      if (this.options.playerNames && /Hero Placeholder/.test(thang.id)) {
        options.playerName = this.options.playerNames[thang.team];
      }
      const lank = new Lank(thangType, options);
      this.listenTo(lank, 'sprite:mouse-up', this.onLankMouseUp);
      this.addLank(lank, null, layer);
      lank.setDebug(this.debug);
      return lank;
    }

    removeLank(lank) {
      lank.layer.removeLank(lank);
      const {
        thang
      } = lank;
      delete this.lanks[lank.thang.id];
      this.lankArray.splice(this.lankArray.indexOf(lank), 1);
      this.stopListening(lank);
      return lank.destroy();
    }

    updateSounds() {
      return Array.from(this.lankArray).map((lank) => lank.playSounds());  // hmm; doesn't work for lanks which we didn't add yet in adjustLankExistence
    }

    update(frameChanged) {
      if (frameChanged) { this.adjustLankExistence(); }
      for (var lank of Array.from(this.lankArray)) { lank.update(frameChanged); }
      if (utils.isCodeCombat) {
        this.updateSelection();
      }
      this.layerAdapters['Default'].updateLayerOrder();
      return this.cacheObstacles();
    }

    adjustLankExistence() {
      // Add anything new, remove anything old, update everything current
      let lank;
      const updatedObstacles = [];
      let itemsJustEquipped = [];
      for (var thang of Array.from(this.world.thangs)) {
        if (thang.exists && thang.pos) {
          if (thang.equip) { itemsJustEquipped = itemsJustEquipped.concat(this.equipNewItems(thang)); }
          if (lank = this.lanks[thang.id]) {
            lank.setThang(thang);  // make sure Lank has latest Thang
            if (this.world.synchronous && !thang.stateless) { thang.stateChanged = true; }  // TODO: think of a more performant thing to do
          } else {
            lank = this.addThangToLanks(thang);
            if (this.world.synchronous && !thang.stateless) { thang.stateChanged = true; }
            Backbone.Mediator.publish('surface:new-thang-added', {thang, sprite: lank});
            if (lank.sprite.parent === this.layerAdapters['Obstacle']) { updatedObstacles.push(lank); }
            lank.playSounds();
          }
        }
      }
      for (var item of Array.from(itemsJustEquipped)) { item.modifyStats(); }
      for (var thangID in this.lanks) {
        lank = this.lanks[thangID];
        var missing = !(lank.notOfThisWorld || (this.world.thangMap[thangID] != null ? this.world.thangMap[thangID].exists : undefined));
        var isObstacle = lank.sprite.parent === this.layerAdapters['Obstacle'];
        if (isObstacle && (missing || lank.hasMoved)) { updatedObstacles.push(lank); }
        lank.hasMoved = false;
        if (missing) { this.removeLank(lank); }
      }
      if (updatedObstacles.length && this.cachedObstacles) { this.cacheObstacles(updatedObstacles); }

      // mainly for handling selecting thangs from session when the thang is not always in existence
      if (this.willSelectThang && this.lanks[this.willSelectThang[0]]) {
        this.selectThang(...Array.from(this.willSelectThang || []));
      }

      return this.updateScreenReader();
    }

    updateScreenReader() {
      if (utils.isOzaria) {
        return this.updateScreenReaderOzaria();
      } else {
        return this.updateScreenReaderCodeCombat();
      }
    }

    updateScreenReaderCodeCombat() {
      // Testing ASCII map for screen readers
      if (me.get('name') !== 'zersiax') { return; }  //in ['zersiax', 'Nick']
      const ascii = $('#ascii-surface');
      const thangs = (Array.from(this.lankArray).map((lank) => lank.thang));
      const bounds = this.world.calculateSimpleMovementBounds();
      const width = Math.min(bounds.right - bounds.left, Math.round(this.camera.worldViewport.width));
      const height = Math.min(bounds.top - bounds.bottom, Math.round(this.camera.worldViewport.height));
      const left = Math.max(bounds.left, Math.round(this.camera.worldViewport.x));
      const bottom = Math.max(bounds.bottom, Math.round(this.camera.worldViewport.y - this.camera.worldViewport.height));  // y is inverted
      const simpleMovementResolution = 10;  // It's always 10 in Ozaria
      const padding = 0;
      const rogue = true;
      const simpleMovementGrid = new Grid(thangs, width, height, padding, left, bottom, rogue, simpleMovementResolution);
      return Backbone.Mediator.publish('surface:update-screen-reader-map', {grid: simpleMovementGrid});
    }

    updateScreenReaderOzaria() {
      if (!__guard__(me.get('aceConfig'), x => x.screenReaderMode) || !utils.isOzaria) { return; }
      const wv = this.camera.worldViewport;
      const thangs = ((() => {
        const result = [];
        for (var lank of Array.from(this.lankArray)) {           if ((wv.x             <= (lank.thang.pos != null ? lank.thang.pos.x : undefined) && (lank.thang.pos != null ? lank.thang.pos.x : undefined) <= wv.x + wv.width) &&
          (wv.y - wv.height <= (lank.thang.pos != null ? lank.thang.pos.y : undefined) && (lank.thang.pos != null ? lank.thang.pos.y : undefined) <= wv.y)) {
            result.push(lank.thang);
          }
        }

        return result;
      })());  // Ignore off-screen Thangs
      let bounds = this.world.calculateSimpleMovementBounds(thangs);
      const width = Math.min(bounds.right - bounds.left, Math.round(wv.width));
      const height = Math.min(bounds.top - bounds.bottom, Math.round(wv.height));
      const left = Math.max(bounds.left, Math.round(wv.x));
      const bottom = Math.max(bounds.bottom, Math.round(wv.y - wv.height));  // y is inverted
      const simpleMovementResolution = 10;  // It's always 10 in Ozaria
      const padding = 0;
      const rogue = true;
      const simpleMovementGrid = new Grid(thangs, width, height, padding, left, bottom, rogue, simpleMovementResolution);
      bounds = {left, bottom, width, height};
      return Backbone.Mediator.publish('surface:update-screen-reader-map', {grid: simpleMovementGrid, bounds});
    }

    equipNewItems(thang) {
      const itemsJustEquipped = [];
      if (thang.equip && !thang.equipped) {
        thang.equip();  // Pretty hacky, but needed since initialize may not be called if we're not running Systems.
        itemsJustEquipped.push(thang);
      }
      if (thang.inventoryIDs) {
        // Even hackier: these items were only created/equipped during simulation, so we reequip here.
        for (var slot in thang.inventoryIDs) {
          var itemID = thang.inventoryIDs[slot];
          var item = this.world.getThangByID(itemID);
          if (!item.equipped) {
            if (!item.equip) { console.log(thang.id, 'equipping', item, 'in', thang.slot, 'Surface-side, but it cannot equip?'); }
            if (typeof item.equip === 'function') {
              item.equip();
            }
            if (item.equip) { itemsJustEquipped.push(item); }
          }
        }
      }
      return itemsJustEquipped;
    }

    cacheObstacles(updatedObstacles=null) {
      let possiblyUpdatedWallLanks;
      let lank;
      if (this.cachedObstacles && !updatedObstacles) { return; }
      const {
        lankArray
      } = this;
      const wallLanks = ((() => {
        const result = [];
        for (lank of Array.from(lankArray)) {           if ((lank.thangType != null ? lank.thangType.get('name').search(/(dungeon|indoor|ice|classroom|vr).wall/i) : undefined) !== -1) {
            result.push(lank);
          }
        }
        return result;
      })());
      if (_.any((Array.from(wallLanks).map((s) => s.stillLoading)))) { return; }
      const walls = ((() => {
        const result1 = [];
        for (lank of Array.from(wallLanks)) {           result1.push(lank.thang);
        }
        return result1;
      })());
      this.world.calculateBounds();
      const wallGrid = new Grid(walls, this.world.width, this.world.height);
      if (updatedObstacles) {
        possiblyUpdatedWallLanks = ((() => {
          const result2 = [];
          for (lank of Array.from(wallLanks)) {             if (_.find(updatedObstacles, w2 => (lank === w2) || ((Math.abs(lank.thang.pos.x - w2.thang.pos.x) + Math.abs(lank.thang.pos.y - w2.thang.pos.y)) <= 16))) {
              result2.push(lank);
            }
          }
          return result2;
        })());
      } else {
        possiblyUpdatedWallLanks = wallLanks;
      }
  //    console.log 'updating up to', possiblyUpdatedWallLanks.length, 'of', wallLanks.length, 'wall lanks from updatedObstacles', updatedObstacles
      for (var wallLank of Array.from(possiblyUpdatedWallLanks)) {
        if (!wallLank.currentRootAction) { wallLank.queueAction('idle'); }
        wallLank.lockAction(false);
        wallLank.updateActionDirection(wallGrid);
        wallLank.lockAction(true);
        wallLank.updateScale();
        wallLank.updatePosition();
      }
  //    console.log wallGrid.toString()
      return this.cachedObstacles = true;
    }

    lankFor(thangID) { return this.lanks[thangID]; }

    onNewWorld(e) {
      this.world = (this.options.world = e.world);
      // Clear obstacle cache for this level, since we are spawning walls dynamically
      if (e.finished && /(kithgard-mastery|dungeon-raider)/.test(window.location.href)) { return this.cachedObstacles = false; }
    }

    play() {
      for (var lank of Array.from(this.lankArray)) { lank.play(); }
      if (utils.isCodeCombat) {
        if (this.selectionMark != null) {
          this.selectionMark.play();
        }
        return (this.targetMark != null ? this.targetMark.play() : undefined);
      }
    }

    stop() {
      for (var lank of Array.from(this.lankArray)) { lank.stop(); }
      if (utils.isCodeCombat) {
        if (this.selectionMark != null) {
          this.selectionMark.stop();
        }
        return (this.targetMark != null ? this.targetMark.stop() : undefined);
      }
    }

    // Selection

    onSuppressSelectionSounds(e) { return this.suppressSelectionSounds = e.suppress; }
    onSetLockSelect(e) { return this.selectLocked = e.lock; }
    onLevelRestarted(e) {
      this.selectLocked = false;
      return this.selectLank(e, null);
    }

    onSelectSprite(e) {
      return this.selectThang(e.thangID, e.spellName);
    }

    onCameraDragged() {
      return this.dragged += 1;
    }

    onCameraZoomUpdated(e) {
      return this.updateScreenReader();
    }

    onLankMouseUp(e) {
      if (!this.handleEvents) { return; }
      if (key.shift) { return; } //and @options.choosing
      if (this.dragged > 3) { return this.dragged = 0; }
      this.dragged = 0;
      const lank = __guard__(e.sprite != null ? e.sprite.thang : undefined, x => x.isSelectable) ? e.sprite : null;
      if (this.flagCursorLank && ((lank != null ? lank.thangType.get('name') : undefined) === 'Flag')) { return; }
      return this.selectLank(e, lank);
    }

    onChangeSelected(gameUIState, selected) {
      let lank;
      let s;
      const oldLanks = ((() => {
        const result = [];
        for (s of Array.from(gameUIState.previousAttributes().selected || [])) {           result.push(s.sprite);
        }
        return result;
      })());
      const newLanks = ((() => {
        const result1 = [];
        for (s of Array.from(selected || [])) {           result1.push(s.sprite);
        }
        return result1;
      })());
      const addedLanks = _.difference(newLanks, oldLanks);
      const removedLanks = _.difference(oldLanks, newLanks);

      for (lank of Array.from(addedLanks)) {
        var layer = lank.sprite.parent !== this.layerAdapters.Default.container ? this.layerAdapters.Default : this.layerAdapters.Ground;
        var mark = new Mark({name: 'selection', camera: this.camera, layer, thangType: 'selection'});
        mark.toggle(true);
        mark.setLank(lank);
        mark.update();
        lank.marks.selection = mark;
      } // TODO: Figure out how to non-hackily assign lank this mark

      return (() => {
        const result2 = [];
        for (lank of Array.from(removedLanks)) {
          result2.push((typeof lank.removeMark === 'function' ? lank.removeMark('selection') : undefined));
        }
        return result2;
      })();
    }

    selectThang(thangID, spellName=null, treemaThangSelected = null) {
      if (!this.lanks[thangID]) { return this.willSelectThang = [thangID, spellName]; }
      return this.selectLank(null, this.lanks[thangID], spellName, treemaThangSelected);
    }

    selectLank(e, lank=null, spellName=null, treemaThangSelected = null) {
      if (e && (this.disabled || this.selectLocked)) { return; }  // Ignore clicks for selection/panning/wizard movement while disabled or select is locked
      let worldPos = __guard__(lank != null ? lank.thang : undefined, x => x.pos);
      if (e != null ? e.originalEvent : undefined) { if (worldPos == null) { worldPos = this.camera.screenToWorld({x: e.originalEvent.rawX, y: e.originalEvent.rawY}); } }
      if (this.handleEvents) {
        if ((!this.reallyStopMoving) && worldPos && (this.options.navigateToSelection || !lank || treemaThangSelected) && (__guard__(__guard__(e != null ? e.originalEvent : undefined, x2 => x2.nativeEvent), x1 => x1.which) !== 3)) {
          this.camera.zoomTo((lank != null ? lank.sprite : undefined) || this.camera.worldToSurface(worldPos), this.camera.zoom, 1000, true);
        }
      }
      if (this.options.choosing) { lank = null; }  // Don't select lanks while choosing
      if (lank !== this.selectedLank) {
        if (this.selectedLank != null) {
          this.selectedLank.selected = false;
        }
        if (lank != null) {
          lank.selected = true;
        }
        this.selectedLank = lank;
      }
      const alive = lank && !(lank.thang.health < 0);

      Backbone.Mediator.publish('surface:sprite-selected', {
        thang: lank ? lank.thang : null,
        sprite: lank,
        spellName: spellName != null ? spellName : (e != null ? e.spellName : undefined),
        originalEvent: e,
        worldPos
      }
      );

      if (lank) { this.willSelectThang = null; }  // Now that we've done a real selection, don't reselect some other Thang later.

      if (alive && !this.suppressSelectionSounds) {
        const instance = lank.playSound('selected');
        if ((instance != null ? instance.playState : undefined) === 'playSucceeded') {
          Backbone.Mediator.publish('sprite:thang-began-talking', {thang: (lank != null ? lank.thang : undefined)});
          return instance.addEventListener('complete', () => Backbone.Mediator.publish('sprite:thang-finished-talking', {thang: (lank != null ? lank.thang : undefined)}));
        }
      }
    }

    onFlagColorSelected(e) {
      if (this.flagCursorLank) { this.removeLank(this.flagCursorLank); }
      this.flagCursorLank = null;
      for (var flagLank of Array.from(this.lankArray)) {
        if (flagLank.thangType.get('name') === 'Flag') {
          flagLank.sprite.cursor = e.color ? 'crosshair' : 'pointer';
        }
      }
      if (!e.color) { return; }
      this.flagCursorLank = new FlagLank(this.thangTypeFor('Flag'), this.createLankOptions({thangID: 'Flag Cursor', color: e.color, team: me.team, isCursor: true, pos: e.pos}));
      return this.addLank(this.flagCursorLank, this.flagCursorLank.thang.id, this.layerAdapters['Floating']);
    }

    onFlagUpdated(e) {
      if (!e.active) { return; }
      const pendingFlag = new FlagLank(this.thangTypeFor('Flag'), this.createLankOptions({thangID: 'Pending Flag ' + Math.random(), color: e.color, team: e.team, isCursor: false, pos: e.pos}));
      this.addLank(pendingFlag, pendingFlag.thang.id, this.layerAdapters['Floating']);
      return this.pendingFlags.push(pendingFlag);
    }

    onFlagAppeared(e) {
      // Remove the pending flag that matches this one's color/team/position, and any color/team matches placed earlier.
      const t1 = e.sprite.thang;
      const pending = (this.pendingFlags != null ? this.pendingFlags : []).slice();
      let foundExactMatch = false;
      for (let i = pending.length - 1; i >= 0; i--) {
        var pendingFlag = pending[i];
        var t2 = pendingFlag.thang;
        var matchedType = (t1.color === t2.color) && (t1.team === t2.team);
        var matched = matchedType && (foundExactMatch || ((Math.abs(t1.pos.x - t2.pos.x) < 0.00001) && (Math.abs(t1.pos.y - t2.pos.y) < 0.00001)));
        if (matched) {
          foundExactMatch = true;
          this.pendingFlags.splice(i, 1);
          this.removeLank(pendingFlag);
        }
      }
      if (e.sprite.sprite != null) {
        e.sprite.sprite.cursor = this.flagCursorLank ? 'crosshair' : 'pointer';
      }
      return null;
    }

    onRemoveSelectedFlag(e) {
      // Remove the selected lank if it's a flag, or any flag of the given color if a color is given.
      const flagLank = _.find([this.selectedLank].concat(this.lankArray), lank => lank && (lank.thangType.get('name') === 'Flag') && (lank.thang.team === me.team) && ((lank.thang.color === e.color) || !e.color) && !lank.notOfThisWorld);
      if (!flagLank) { return; }
      return Backbone.Mediator.publish('surface:remove-flag', {color: flagLank.thang.color});
    }

    // Marks

    updateSelection() {
      if ((this.selectedLank != null ? this.selectedLank.thang : undefined) && (!this.selectedLank.thang.exists || !this.world.getThangByID(this.selectedLank.thang.id))) {
        const thangID = this.selectedLank.thang.id;
        this.selectedLank = null;  // Don't actually trigger deselection, but remove the selected lank.
        if (this.selectionMark != null) {
          this.selectionMark.toggle(false);
        }
        this.willSelectThang = [thangID, null];
      }
      this.updateTarget();
      if (!this.selectionMark) { return; }
      if (this.selectedLank && (this.selectedLank.destroyed || !this.selectedLank.thang)) { this.selectedLank = null; }
      // The selection mark should be on the ground layer, unless we're not a normal lank (like a wall), in which case we'll place it higher so we can see it.
      if (this.selectedLank && (this.selectedLank.sprite.parent !== this.layerAdapters.Default.container)) {
        this.selectionMark.setLayer(this.layerAdapters.Default);
      } else if (this.selectedLank) {
        this.selectionMark.setLayer(this.layerAdapters.Ground);
      }
      this.selectionMark.toggle(this.selectedLank != null);
      this.selectionMark.setLank(this.selectedLank);
      return this.selectionMark.update();
    }

    updateTarget() {
      if (!this.targetMark) { return; }
      const thang = this.selectedLank != null ? this.selectedLank.thang : undefined;
      const target = thang != null ? thang.target : undefined;
      let targetPos = thang != null ? thang.targetPos : undefined;
      if (__guardMethod__(targetPos, 'isZero', o => o.isZero())) { targetPos = null; }  // Null targetPos get serialized as (0, 0, 0)
      this.targetMark.setLank(target ? this.lanks[target.id] : null);
      this.targetMark.toggle(this.targetMark.lank || targetPos);
      return this.targetMark.update(targetPos ? this.camera.worldToSurface(targetPos) : null);
    }
  };
  LankBoss.initClass();
  return LankBoss;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}
function __guardMethod__(obj, methodName, transform) {
  if (typeof obj !== 'undefined' && obj !== null && typeof obj[methodName] === 'function') {
    return transform(obj, methodName);
  } else {
    return undefined;
  }
}