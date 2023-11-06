// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
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
let ThangsTabView;
require('app/styles/editor/level/thangs-tab-view.sass');
const CocoView = require('views/core/CocoView');
const AddThangsView = require('./AddThangsView');
const thangs_template = require('app/templates/editor/level/thangs-tab-view');
const Level = require('models/Level');
const ThangType = require('models/ThangType');
const LevelComponent = require('models/LevelComponent');
const CocoCollection = require('collections/CocoCollection');
const {isObjectID} = require('models/CocoModel');
const Surface = require('lib/surface/Surface');
const Thang = require('lib/world/thang');
const LevelThangEditView = require('./LevelThangEditView');
const LevelComponents = require('collections/LevelComponents');
require('lib/setupTreema');
const GameUIState = require('models/GameUIState');
const GenerateTerrainModal = require('views/editor/level/modals/GenerateTerrainModal');
const utils = require('core/utils');

// Server-side Thangs collection fetch limit
const PAGE_SIZE = 1000;

// Moving the screen while dragging thangs constants
const MOVE_MARGIN = 0.15;
const MOVE_SPEED = 13;


// Let us place these on top of other Thangs
const overlappableThangTypeNames = ['Torch', 'Chains', 'Bird', 'Cloud 1', 'Cloud 2', 'Cloud 3', 'Waterfall', 'Obstacle', 'Electrowall', 'Spike Walls'];

class ThangTypeSearchCollection extends CocoCollection {
  static initClass() {
    this.prototype.url = '/db/thang.type?project=original,name,version,slug,kind,components,prerenderedSpriteSheetData';
    this.prototype.model = ThangType;
  }
}
ThangTypeSearchCollection.initClass();

module.exports = (ThangsTabView = (function() {
  ThangsTabView = class ThangsTabView extends CocoView {
    static initClass() {
      this.prototype.id = 'thangs-tab-view';
      this.prototype.className = 'tab-pane active';
      this.prototype.template = thangs_template;

      this.prototype.subscriptions = {
        'surface:mouse-moved': 'onSurfaceMouseMoved',
        'surface:mouse-over': 'onSurfaceMouseOver',
        'surface:mouse-out': 'onSurfaceMouseOut',
        'editor:edit-level-thang': 'editThang',
        'editor:level-thang-edited': 'onLevelThangEdited',
        'editor:level-thang-done-editing': 'onLevelThangDoneEditing',
        'editor:view-switched': 'onViewSwitched',
        'sprite:dragged': 'onSpriteDragged',
        'sprite:mouse-up': 'onSpriteMouseUp',
        'sprite:double-clicked': 'onSpriteDoubleClicked',
        'surface:stage-mouse-down': 'onStageMouseDown',
        'surface:stage-mouse-up': 'onStageMouseUp',
        'editor:random-terrain-generated': 'onRandomTerrainGenerated'
      };

      this.prototype.events = {
        'click #extant-thangs-filter button': 'onFilterExtantThangs',
        'click #delete': 'onDeleteClicked',
        'click #duplicate': 'onDuplicateClicked',
        'click #thangs-container-toggle': 'toggleThangsContainer',
        'click #thangs-palette-toggle': 'toggleThangsPalette',
    //    'click .add-thang-palette-icon': 'toggleThangsPalette'
        'click #rotation-menu-item button': 'onClickRotationButton',
        'click [data-toggle="coco-modal"][data-target="editor/level/modals/GenerateTerrainModal"]': 'openGenerateTerrainModal'
      };

      this.prototype.shortcuts = {
        'esc': 'selectAddThang',
        'delete, del, backspace': 'deleteSelectedExtantThang',
        'ctrl+z, ⌘+z': 'undo',
        'ctrl+shift+z, ⌘+shift+z': 'redo',
        'alt+c': 'toggleSelectedThangCollision',
        'left'() { return this.moveSelectedThangBy(-1, 0); },
        'right'() { return this.moveSelectedThangBy(1, 0); },
        'up'() { return this.moveSelectedThangBy(0, 1); },
        'down'() { return this.moveSelectedThangBy(0, -1); },
        'alt+left'() { if (!key.shift) { return this.rotateSelectedThangTo(Math.PI); } },
        'alt+right'() { if (!key.shift) { return this.rotateSelectedThangTo(0); } },
        'alt+up'() { return this.rotateSelectedThangTo(-Math.PI / 2); },
        'alt+down'() { return this.rotateSelectedThangTo(Math.PI / 2); },
        'alt+shift+left'() { return this.rotateSelectedThangBy(Math.PI / 16); },
        'alt+shift+right'() { return this.rotateSelectedThangBy(-Math.PI / 16); },
        'shift+left'() { return this.resizeSelectedThangBy(-1, 0); },
        'shift+right'() { return this.resizeSelectedThangBy(1, 0); },
        'shift+up'() { return this.resizeSelectedThangBy(0, 1); },
        'shift+down'() { return this.resizeSelectedThangBy(0, -1); }
      };
    }

    constructor(options) {
      super(options);
      this.selectAddThang = this.selectAddThang.bind(this);
      this.moveSide = this.moveSide.bind(this);
      this.deleteSelectedExtantThang = this.deleteSelectedExtantThang.bind(this);
      this.onThangsChanged = this.onThangsChanged.bind(this);
      this.onTreemaThangSelected = this.onTreemaThangSelected.bind(this);
      this.onTreemaThangDoubleClicked = this.onTreemaThangDoubleClicked.bind(this);
      this.world = options.world;
      this.gameUIState = new GameUIState();
      this.listenTo(this.gameUIState, 'sprite:mouse-down', this.onSpriteMouseDown);
      this.listenTo(this.gameUIState, 'surface:stage-mouse-move', this.onStageMouseMove);
      this.listenTo(this.gameUIState, 'change:selected', this.onChangeSelected);

      this.thangTypes = new Backbone.Collection();
      const thangTypeCollection = new ThangTypeSearchCollection([]);
      thangTypeCollection.url += '&archived=false';
      thangTypeCollection.fetch({data: {limit: PAGE_SIZE}});
      thangTypeCollection.skip = 0;
      // should load depended-on Components, too
      this.supermodel.loadCollection(thangTypeCollection, 'thangs');
      this.listenToOnce(thangTypeCollection, 'sync', this.onThangCollectionSynced);

      // just loading all Components for now: https://github.com/codecombat/codecombat/issues/405
      this.componentCollection = new LevelComponents([], {saveBackups: true});
      this.componentCollection.url += '?archived=false';
      this.supermodel.trackRequest(this.componentCollection.fetch());
      this.listenToOnce(this.componentCollection, 'sync', function() {
        return (() => {
          const result = [];
          for (var component of Array.from(this.componentCollection.models)) {
            component.url = `/db/level.component/${component.get('original')}/version/${component.get('version').major}`;
            result.push(this.supermodel.registerModel(component));
          }
          return result;
        })();
      });
      this.level = options.level;
      this.onThangsChanged = _.debounce(this.onThangsChanged);

      $(document).bind('contextmenu', this.preventDefaultContextMenu);
    }

    onThangCollectionSynced(collection) {
      if (!__guard__(collection != null ? collection.models : undefined, x => x.length)) { return; }
      const getMore = collection.models.length === PAGE_SIZE;
      this.thangTypes.add(collection.models);
      if (getMore) {
        collection.skip += PAGE_SIZE;
        collection.fetch({data: {skip: collection.skip, limit: PAGE_SIZE}});
        this.supermodel.loadCollection(collection, 'thangs');
        return this.listenToOnce(collection, 'sync', this.onThangCollectionSynced);
      }
    }

    getRenderData(context) {
      let thangType;
      if (context == null) { context = {}; }
      context = super.getRenderData(context);
      if (!this.supermodel.finished()) { return context; }
      for (thangType of Array.from(this.thangTypes.models)) {
        thangType.notInLevel = true;
      }
      let thangTypes = ((() => {
        const result = [];
        for (thangType of Array.from(this.supermodel.getModels(ThangType))) {           result.push(thangType.attributes);
        }
        return result;
      })());
      thangTypes = _.uniq(thangTypes, false, 'original');
      thangTypes = _.reject(thangTypes, tt => ['Mark', undefined].includes(tt.kind));
      const groupMap = {};
      for (thangType of Array.from(thangTypes)) {
        if (groupMap[thangType.kind] == null) { groupMap[thangType.kind] = []; }
        groupMap[thangType.kind].push(thangType);
      }

      const groups = [];
      for (var groupName of Array.from(Object.keys(groupMap).sort())) {
        var someThangTypes = groupMap[groupName];
        someThangTypes = _.sortBy(someThangTypes, 'name');
        var group = {
          name: groupName,
          thangs: someThangTypes
        };
        groups.push(group);
      }

      context.thangTypes = thangTypes;
      context.groups = groups;
      return context;
    }

    undo(e) {
      if (!this.editThangView) { return this.thangsTreema.undo(); } else { return this.editThangView.undo(); }
    }

    redo(e) {
      if (!this.editThangView) { return this.thangsTreema.redo(); } else { return this.editThangView.redo(); }
    }

    afterRender() {
      super.afterRender();
      if (!this.supermodel.finished()) { return; }
      $('.tab-content').mousedown(this.selectAddThang);
      $('#thangs-list').bind('mousewheel', this.preventBodyScrollingInThangList);
      this.$el.find('#extant-thangs-filter button:first').button('toggle');
      $(window).on('resize', this.onWindowResize);
      this.addThangsView = this.insertSubView(new AddThangsView({world: this.world}));
      this.buildInterface(); // refactor to not have this trigger when this view re-renders?
      if (_.keys(this.thangsTreema.data).length) {
        return this.$el.find('#canvas-overlay').css('display', 'none');
      }
    }

    openGenerateTerrainModal(e) {
      e.stopPropagation();
      return this.openModalView(new GenerateTerrainModal());
    }

    onFilterExtantThangs(e) {
      this.$el.find('#extant-thangs-filter button.active').button('toggle');
      const button = $(e.target).closest('button');
      button.button('toggle');
      const val = button.val();
      if (this.lastHideClass) { this.thangsTreema.$el.removeClass(this.lastHideClass); }
      if (val) { return this.thangsTreema.$el.addClass(this.lastHideClass = `hide-except-${val}`); }
    }

    preventBodyScrollingInThangList(e) {
      this.scrollTop += (e.deltaY < 0 ? 1 : -1) * 30;
      return e.preventDefault();
    }

    buildInterface(e) {
      if (e) { this.level = e.level; }

      const data = $.extend(true, [], this.level.attributes.thangs != null ? this.level.attributes.thangs : []);
      const thangsObject = this.groupThangs(data);

      const schema = {
        type: 'object',
        format: 'thangs-folder',
        additionalProperties: {
          anyOf: [
            {
              type: 'object',
              format: 'thang',
              required: ['thangType', 'id']
            },
            { $ref: '#' }
          ]
        }
      };

      const treemaOptions = {
        schema,
        data: thangsObject,
        skipValidation: true,
        supermodel: this.supermodel,
        callbacks: {
          change: this.onThangsChanged,
          select: this.onTreemaThangSelected,
          dblclick: this.onTreemaThangDoubleClicked
        },
        readOnly: true,
        nodeClasses: {
          thang: ThangNode,
          'thangs-folder': ThangsFolderNode
        },
        world: this.world
      };

      this.thangsTreema = this.$el.find('#thangs-treema').treema(treemaOptions);
      this.thangsTreema.build();
      this.thangsTreema.open();
      this.openSmallerFolders(this.thangsTreema);

      this.onThangsChanged();  // Initialize the World with Thangs
      this.initSurface();
      const thangsHeaderHeight = $('#thangs-header').height();
      const oldHeight = $('#thangs-list').height();
      $('#thangs-list').height(oldHeight - thangsHeaderHeight);
      if (data != null ? data.length : undefined) {
        return this.$el.find('.generate-terrain-button').hide();
      }
    }

    openSmallerFolders(folderTreema) {
      const children = _.values(folderTreema.childrenTreemas);
      return (() => {
        const result = [];
        for (var child of Array.from(children)) {
          if (child.data.thangType) { continue; }
          if (_.keys(child.data).length < 5) {
            child.open();
            result.push(this.openSmallerFolders(child));
          } else {
            result.push(undefined);
          }
        }
        return result;
      })();
    }

    initSurface() {
      const webGLCanvas = $('canvas#webgl-surface', this.$el);
      const normalCanvas = $('canvas#normal-surface', this.$el);
      this.surface = new Surface(this.world, normalCanvas, webGLCanvas, {
        paths: false,
        coords: true,
        grid: true,
        navigateToSelection: false,
        thangTypes: this.supermodel.getModels(ThangType),
        showInvisible: true,
        frameRate: 15,
        levelType: this.level.get('type', true),
        gameUIState: this.gameUIState,
        handleEvents: false
      });
      this.surface.playing = false;
      this.surface.setWorld(this.world);
      this.surface.lankBoss.suppressSelectionSounds = true;
      return this.centerCamera();
    }

    centerCamera() {
      let [width, height] = Array.from(this.world.size());
      width = Math.max(width, 80);
      height = Math.max(height, 68);
      const {left, top, right, bottom} = this.world.getBounds();
      const center = {x: left + (width / 2), y: bottom + (height / 2)};
      const sup = this.surface.camera.worldToSurface(center);
      const zoom = (0.94 * 92.4) / width;  // Zoom 1.0 lets us see 92.4 meters.
      return this.surface.camera.zoomTo(sup, zoom, 0);
    }

    destroy() {
      this.selectAddThangType(null);
      if (this.surface != null) {
        this.surface.destroy();
      }
      $(window).off('resize', this.onWindowResize);
      $(document).unbind('contextmenu', this.preventDefaultContextMenu);
      if (this.thangsTreema != null) {
        this.thangsTreema.destroy();
      }
      return super.destroy();
    }

    onViewSwitched(e) {
      this.selectAddThang(null, true);
      return __guard__(this.surface != null ? this.surface.lankBoss : undefined, x => x.selectLank(null, null));
    }

    onStageMouseDown(e) {
      // initial values for a mouse click lifecycle
      this.dragged = 0;
      this.willUnselectSprite = false;
      this.gameUIState.set('canDragCamera', true);

      if ((this.addThangLank != null ? this.addThangLank.thangType.get('kind') : undefined) === 'Wall') {
        this.paintingWalls = true;
        return this.gameUIState.set('canDragCamera', false);

      } else if (this.addThangLank) {
        // We clicked on the background when we had an add Thang selected, so add it
        return this.addThang(this.addThangType, this.addThangLank.thang.pos);

      } else if (e.onBackground) {
        return this.gameUIState.set('selected', []);
      }
    }

    onStageMouseMove(e) {
      return this.dragged += 1;
    }

    onStageMouseUp(e) {
      this.paintingWalls = false;
      return $('#contextmenu').hide();
    }

    onSpriteMouseDown(e) {
      const {
        nativeEvent
      } = e.originalEvent;
      // update selection
      let selected = [];
      if (nativeEvent.metaKey || nativeEvent.ctrlKey) {
        selected = _.clone(this.gameUIState.get('selected'));
      }
      if (e.thang != null ? e.thang.isSelectable : undefined) {
        const alreadySelected = _.find(selected, s => s.thang === e.thang);
        if (alreadySelected) {
          // move to end (make it the last selected) and maybe unselect it
          this.willUnselectSprite = true;
          selected = _.without(selected, alreadySelected);
        }
        selected.push({ thang: e.thang, sprite: e.sprite, spellName: e.spellName });
      }
      if (_.any(selected) && key.alt) {
        // Clone selected thang instead of selecting it
        const lastSelected = _.last(selected);
        this.selectAddThangType(lastSelected.thang.spriteName, lastSelected.thang);
        selected = [];
      }
      this.gameUIState.set('selected', selected);
      if (_.any(selected)) {
        return this.gameUIState.set('canDragCamera', false);
      }
    }

    onSpriteDragged(e) {
      const selected = this.gameUIState.get('selected');
      if (!_.any(selected) || !(this.dragged > 10)) { return; }
      this.willUnselectSprite = false;
      const {stageX, stageY} = e.originalEvent;

      // move the one under the mouse
      const lastSelected = _.last(selected);
      const cap = this.surface.camera.screenToCanvas({x: stageX, y: stageY});
      const wop = this.surface.camera.canvasToWorld(cap);
      wop.z = lastSelected.thang.depth / 2;
      const posBefore = _.clone(lastSelected.thang.pos);
      this.adjustThangPos(lastSelected.sprite, lastSelected.thang, wop);
      const posAfter = lastSelected.thang.pos;

      // move any others selected, proportionally to how the 'main' sprite moved
      const xDiff = posAfter.x - posBefore.x;
      const yDiff = posAfter.y - posBefore.y;
      if (xDiff || yDiff) {
        for (var singleSelected of Array.from(selected.slice(0, selected.length - 1))) {
          var newPos = {
            x: singleSelected.thang.pos.x + xDiff,
            y: singleSelected.thang.pos.y + yDiff
          };
          this.adjustThangPos(singleSelected.sprite, singleSelected.thang, newPos);
        }
      }

      // move the camera if we're on the edge of the screen
      let [w, h] = Array.from([this.surface.camera.canvasWidth, this.surface.camera.canvasHeight]);
      const sidebarWidths = (['#all-thangs', '#add-thangs-view'].map((id) => (this.$el.find(id).hasClass('hide') ? 0 : (this.$el.find(id).outerWidth() / this.surface.camera.canvasScaleFactorX))));
      for (var sidebarWidth of Array.from(sidebarWidths)) { w -= sidebarWidth; }
      cap.x -= sidebarWidths[0];
      return this.calculateMovement(cap.x / w, cap.y / h, w / h);
    }

    onSpriteMouseUp(e) {
      const selected = this.gameUIState.get('selected');
      if ((e.originalEvent.nativeEvent.button === 2) && _.any(selected)) {
        this.onSpriteContextMenu(e);
      }
      if (this.movementInterval != null) { clearInterval(this.movementInterval); }
      this.movementInterval = null;

      if (!_.any(selected)) { return; }

      for (var singleSelected of Array.from(selected)) {
        var left, path;
        var {
          pos
        } = singleSelected.thang;

        var thang = _.find((left = this.level.get('thangs')) != null ? left : [], {id: singleSelected.thang.id});
        if (utils.isCodeCombat) {
          path = `${this.pathForThang(thang)}/components/original=${LevelComponent.PhysicalID}`;
        } else {
          var positionComponent = _.find(thang.components || [], c => Array.from(LevelComponent.positionIDs).includes(c.original));
          if (!positionComponent) { continue; }
          path = `${this.pathForThang(thang)}/components/original=${positionComponent.original}`;
        }
        var physical = this.thangsTreema.get(path);
        if (!physical || ((physical.config.pos.x === pos.x) && (physical.config.pos.y === pos.y))) { continue; }
        this.thangsTreema.set(path + '/config/pos', {x: pos.x, y: pos.y, z: pos.z});
      }

      if (this.willUnselectSprite) {
        const clickedSprite = _.find(selected, {sprite: e.sprite});
        return this.gameUIState.set('selected', _.without(selected, clickedSprite));
      }
    }

    onSpriteDoubleClicked(e) {
      if (this.dragged > 10) { return; }
      if (!e.thang) { return; }
      return this.editThang({thangID: e.thang.id});
    }

    onRandomTerrainGenerated(e) {
      let thang;
      this.thangsBatch = [];
      this.hush = true;
      const nonRandomThangs = ((() => {
        const result = [];
        for (thang of Array.from(this.flattenThangs(this.thangsTreema.data))) {           if (!/Random/.test(thang.id)) {
            result.push(thang);
          }
        }
        return result;
      })());
      this.thangsTreema.set('', this.groupThangs(nonRandomThangs));

      const listening = {};
      for (thang of Array.from(e.thangs)) {
        this.selectAddThangType(thang.id);

        // kind of a hack to get the walls to show up correctly when they load.
        // might also fix other thangs who need to show up looking a certain way based on thang type components
        if (!this.addThangType.isFullyLoaded() && !listening[this.addThangType.cid]) {
          listening[this.addThangType.cid] = true;
          this.listenToOnce(this.addThangType, 'build-complete', this.onThangsChanged);
        }

        this.addThang(this.addThangType, thang.pos, true);
      }
      this.hush = false;
      this.onThangsChanged();
      return this.selectAddThangType(null);
    }

    onChangeSelected(gameUIState, selected) {
      let needle;
      const previousSprite = __guard__(__guard__(gameUIState.previousAttributes(), x1 => x1.selected), x => x.sprite);
      const sprite = selected != null ? selected.sprite : undefined;
      const thang = selected != null ? selected.thang : undefined;

      if (previousSprite !== sprite) { __guardMethod__(previousSprite, 'setNameLabel', o => o.setNameLabel(null)); }

      if (thang && !(this.addThangLank && (needle = this.addThangType.get('name'), Array.from(overlappableThangTypeNames).includes(needle)))) {
        // We clicked on a Thang (or its Treema), so select the Thang
        this.selectAddThang(null, true);
        this.selectedExtantThangClickTime = new Date();
        // Show the label above selected thang, notice that we may get here from thang-edit-view, so it will be selected but no label
        sprite.setNameLabel(sprite.thangType.get('name') + ': ' + thang.id);
        sprite.updateLabels();
        return sprite.updateMarks();
      }
    }

    justAdded() { return this.lastAddTime && ((new Date() - this.lastAddTime) < 150); }

    selectAddThang(e, forceDeselect) {
      let target;
      if (forceDeselect == null) { forceDeselect = false; }
      if ((e != null) && $(e.target).closest('#thang-search').length) { return; } // Ignore if you're trying to search thangs
      if (((e == null) || !$(e.target).closest('#thangs-tab-view').length) && !key.isPressed('esc') && !forceDeselect) { return; }
      if (e) { target = $(e.target); } else { target = this.$el.find('.add-thangs-palette'); }  // pretend to click on background if no event
      if (target.attr('id') === 'webgl-surface') { return true; }
      target = target.closest('.add-thang-palette-icon');
      const wasSelected = target.hasClass('selected');
      this.$el.find('.add-thangs-palette .add-thang-palette-icon.selected').removeClass('selected');
      if (!key.alt && !key.meta) { this.selectAddThangType(wasSelected ? null : target.attr('data-thang-type')); }
      __guardMethod__(this.addThangLank, 'playSound', o => o.playSound('selected'));
      if (this.addThangType) { return target.addClass('selected'); }
    }

    moveAddThangSelection(direction) {
      if (!this.addThangType) { return; }
      const icons = $('.add-thangs-palette .add-thang-palette-icon');
      const selectedIcon = icons.filter('.selected');
      const selectedIndex = icons.index(selectedIcon);
      const nextSelectedIndex = (selectedIndex + direction + icons.length) % icons.length;
      return this.selectAddThang({target: icons[nextSelectedIndex]});
    }

    selectAddThangType(type, cloneSourceThang) {
      this.cloneSourceThang = cloneSourceThang;
      if (_.isString(type)) {
        type = _.find(this.supermodel.getModels(ThangType), m => m.get('name') === type);
      }
      let pos = this.addThangLank != null ? this.addThangLank.thang.pos : undefined;  // Maintain old sprite's pos if we have it
      if (this.addThangLank) { this.surface.lankBoss.removeLank(this.addThangLank); }
      this.addThangType = type;
      if (this.addThangType) {
        this.surface.lankBoss.reallyStopMoving = true;
        const thang = this.createAddThang();
        this.addThangLank = this.surface.lankBoss.addThangToLanks(thang, this.surface.lankBoss.layerAdapters['Floating']);
        this.addThangLank.notOfThisWorld = true;
        this.addThangLank.sprite.alpha = 0.75;
        if (pos == null) { pos = {x: Math.round(this.world.width / 2), y: Math.round(this.world.height / 2)}; }
        return this.adjustThangPos(this.addThangLank, thang, pos);
      } else {
        this.addThangLank = null;
        return (this.surface != null ? this.surface.lankBoss.reallyStopMoving = false : undefined);
      }
    }

    createEssentialComponents(defaultComponents) {
      let physicalOriginal;
      const physicalConfig = {pos: {x: 10, y: 10, z: 1}};
      if (physicalOriginal = _.find(defaultComponents != null ? defaultComponents : [], {original: LevelComponent.PhysicalID})) {
        physicalConfig.pos.z = __guard__(physicalOriginal.config != null ? physicalOriginal.config.pos : undefined, x => x.z) != null ? __guard__(physicalOriginal.config != null ? physicalOriginal.config.pos : undefined, x => x.z) : 1;  // Get the z right
      }
      return [
        {original: LevelComponent.ExistsID, majorVersion: 0, config: {}},
        {original: LevelComponent.PhysicalID, majorVersion: 0, config: physicalConfig}
      ];
    }

    createAddThang() {
      let left;
      const allComponents = (Array.from(this.supermodel.getModels(LevelComponent)).map((lc) => lc.attributes));
      let rawComponents = (left = this.addThangType.get('components')) != null ? left : [];
      if (!rawComponents.length) { rawComponents = this.createEssentialComponents(); }
      const mockThang = {components: rawComponents};
      this.level.sortThangComponents([mockThang], allComponents);
      const components = [];
      for (var raw of Array.from(mockThang.components)) {
        var comp = _.find(allComponents, {original: raw.original});
        if (['Selectable', 'Attackable'].includes(comp.name)) { continue; }  // Don't draw health bars or intercept clicks
        var componentClass = this.world.loadClassFromCode(comp.js, comp.name, 'component');
        components.push([componentClass, raw.config]);
      }
      const thang = new Thang(this.world, this.addThangType.get('name'), 'Add Thang Phantom');
      thang.addComponents(...Array.from(components || []));
      return thang;
    }

    adjustThangPos(sprite, thang, pos) {
      if (key.shift) {
        // Meter resolution when holding shift, not caring about thang size.
        pos.x = Math.round(pos.x);
        pos.y = Math.round(pos.y);
      } else {
        const snap = __guard__(sprite != null ? sprite.data : undefined, x => x.snap) || __guard__(sprite != null ? sprite.thangType : undefined, x1 => x1.get('snap')) || {x: 0.01, y: 0.01};  // Centimeter resolution by default
        pos.x = (Math.round((pos.x - ((thang.width != null ? thang.width : 1) / 2)) / snap.x) * snap.x) + ((thang.width != null ? thang.width : 1) / 2);
        pos.y = (Math.round((pos.y - ((thang.height != null ? thang.height : 1) / 2)) / snap.y) * snap.y) + ((thang.height != null ? thang.height : 1) / 2);
      }
      pos.z = thang.depth / 2;
      thang.pos = pos;
      thang.stateChanged = true;
      return this.surface.lankBoss.update(true);  // Make sure Obstacle layer resets cache
    }

    onSurfaceMouseMoved(e) {
      if (!this.addThangLank) { return; }
      const wop = this.surface.camera.screenToWorld({x: e.x, y: e.y});
      wop.z = 0.5;
      this.adjustThangPos(this.addThangLank, this.addThangLank.thang, wop);
      if (this.paintingWalls) {
        if (!_.find(this.surface.lankBoss.lankArray, (lank => {
          return (lank.thangType.get('kind') === 'Wall') &&
          (Math.abs(lank.thang.pos.x - this.addThangLank.thang.pos.x) < 2) &&
          (Math.abs(lank.thang.pos.y - this.addThangLank.thang.pos.y) < 2) &&
          (lank !== this.addThangLank);
        })
        )) {
          this.addThang(this.addThangType, this.addThangLank.thang.pos);
          this.lastAddTime = new Date();
          this.paintedWalls = true;
        }
      }
      return null;
    }

    onSurfaceMouseOver(e) {
      if (!this.addThangLank) { return; }
      return this.addThangLank.sprite.visible = true;
    }

    onSurfaceMouseOut(e) {
      if (!this.addThangLank) { return; }
      return this.addThangLank.sprite.visible = false;
    }

    calculateMovement(pctX, pctY, widthHeightRatio) {
      const MOVE_TOP_MARGIN = 1.0 - MOVE_MARGIN;
      if ((MOVE_TOP_MARGIN > pctX && pctX > MOVE_MARGIN) && (MOVE_TOP_MARGIN > pctY && pctY > MOVE_MARGIN)) {
        if (this.movementInterval != null) { clearInterval(this.movementInterval); }
        this.movementInterval = null;
        return this.moveLatitude = (this.moveLongitude = (this.speed = 0));
      }

      // calculating speed to be 0.0 to 1.0 within the movement buffer on the outer edge
      const diff = (MOVE_MARGIN * 2); // comments are assuming MOVE_MARGIN is 0.1
      this.speed = Math.max(Math.abs(pctX-0.5), Math.abs(pctY-0.5)) * 2; // pct is now 0.8 - 1.0
      this.speed -= 1.0 - diff; // 0.0 - 0.2
      this.speed *= (1.0 / diff); // 0.0 - 1.0
      this.speed *= MOVE_SPEED;

      this.moveLatitude = (pctX * 2) - 1;
      this.moveLongitude = (pctY * 2) - 1;
      if (widthHeightRatio > 1.0) { this.moveLongitude /= widthHeightRatio; }
      if (widthHeightRatio < 1.0) { this.moveLatitude *= widthHeightRatio; }
      if (this.movementInterval == null) { return this.movementInterval = setInterval(this.moveSide, 16); }
    }

    moveSide() {
      if (!this.speed) { return; }
      const c = this.surface.camera;
      const p = {x: c.target.x + ((this.moveLatitude * this.speed) / c.zoom), y: c.target.y + ((this.moveLongitude * this.speed) / c.zoom)};
      return c.zoomTo(p, c.zoom, 0);
    }

    deleteSelectedExtantThang(e) {
      if ($(e.target).hasClass('treema-node')) { return; }
      const selected = this.gameUIState.get('selected');
      if (!_.any(selected)) { return; }

      for (var singleSelected of Array.from(selected)) {
        var thang = this.getThangByID(singleSelected.thang.id);
        this.thangsTreema.delete(this.pathForThang(thang));
        this.deleteEmptyTreema(thang);
        Thang.resetThangIDs();  // TODO: find some way to do this when we delete from treema, too
        Backbone.Mediator.publish('editor:thang-deleted', {thangID: thang.id});
      }
      return this.gameUIState.set('selected', []);
    }

    deleteEmptyTreema(thang){
      const thangType = this.supermodel.getModelByOriginal(ThangType, thang.thangType);
      const children = this.thangsTreema.childrenTreemas;
      const thangKind = children[thangType.get('kind', true)].data;
      const thangName = thangKind[thangType.get('name', true)];
      if (Object.keys(thangName).length === 0) {
        let folderPath = [thangType.get('kind', true), thangType.get('name', true)].join('/');
        this.thangsTreema.delete(folderPath);
        if (Object.keys(thangKind).length === 0) {
          folderPath = [thangType.get('kind', true)].join('/');
          return this.thangsTreema.delete(folderPath);
        }
      }
    }

    groupThangs(thangs) {
      // array of thangs -> foldered thangs
      const grouped = {};
      for (let index = 0; index < thangs.length; index++) {
        var thang = thangs[index];
        var path = this.folderForThang(thang);
        var obj = grouped;
        for (var key of Array.from(path)) {
          if (obj[key] == null) { obj[key] = {}; }
          obj = obj[key];
        }
        obj[thang.id] = thang;
        thang.index = index;
      }
      return grouped;
    }

    folderForThang(thang) {
      const thangType = this.supermodel.getModelByOriginal(ThangType, thang.thangType);
      if (!thangType.get('kind', true)) { console.error('uhh, we had kind', thangType.get('kind', true), 'for', thangType); }
      return [thangType.get('kind', true), thangType.get('name', true)];
    }

    pathForThang(thang) {
      const folder = this.folderForThang(thang);
      folder.push(thang.id);
      return folder.join('/');
    }

    flattenThangs(thangs) {
      // foldered thangs -> array of thangs
      let flattened = [];
      for (var key in thangs) {
        var value = thangs[key];
        if ((value.id != null) && value.thangType) {
          flattened.push(value);
        } else {
          flattened = flattened.concat(this.flattenThangs(value));
        }
      }
      return flattened;
    }

    populateFoldersForThang(thang) {
      const thangFolder = this.folderForThang(thang);
      let prefix = '';
      return (() => {
        const result = [];
        for (var segment of Array.from(thangFolder)) {
          if (prefix) { prefix += '/'; }
          prefix += segment;
          if (!this.thangsTreema.get(prefix)) { result.push(this.thangsTreema.set(prefix, {})); } else {
            result.push(undefined);
          }
        }
        return result;
      })();
    }

    onThangsChanged(skipSerialization) {
      let thang;
      if (this.hush) { return; }

      // keep the thangs in the same order as before, roughly
      let thangs = this.flattenThangs(this.thangsTreema.data);
      thangs = $.extend(true, [], thangs);
      thangs = _.sortBy(thangs, 'index');
      for (thang of Array.from(thangs)) { delete thang.index; }

      this.level.set('thangs', thangs);
      Backbone.Mediator.publish('editor:level-thangs-changed', {thangs});
      if (this.editThangView) { return; }
      if (skipSerialization) { return; }
      const serializedLevel = this.level.serialize({supermodel: this.supermodel, session: null, otherSession: null, headless: false, sessionless: true, cached: true});
      try {
        this.world.loadFromLevel(serializedLevel, false);
      } catch (error) {
        console.error('Catastrophic error loading the level:', error);
      }
      for (thang of Array.from(this.world.thangs)) { thang.isSelectable = !thang.isLand; }  // let us select walls and such
      if (this.surface != null) {
        this.surface.setWorld(this.world);
      }
      if (this.surface != null) {
        this.surface.lankBoss.cachedObstacles = false;
      }
      if (this.addThangType) { this.selectAddThangType(this.addThangType, this.cloneSourceThang); }  // make another addThang sprite, since the World just refreshed

      // update selection, since the thangs have been remade
      const selected = this.gameUIState.get('selected');
      if (_.any(selected)) {
        for (var singleSelected of Array.from(selected)) {
          var sprite = this.surface.lankBoss.lanks[singleSelected.thang.id];
          if (sprite) {
            sprite.updateMarks();
            singleSelected.sprite = sprite;
            singleSelected.thang = sprite.thang;
          }
        }
      }
      return Backbone.Mediator.publish('editor:thangs-edited', {thangs: this.world.thangs});
    }

    onTreemaThangSelected(e, selectedTreemas) {
      const selectedThangTreemas = _.filter(selectedTreemas, t => t instanceof ThangNode);
      const thangIDs = (Array.from(selectedThangTreemas).map((node) => node.data.id));
      const lanks = (Array.from(thangIDs).filter((thangID) => thangID).map((thangID) => this.surface.lankBoss.lanks[thangID]));
      const selected = (Array.from(lanks).filter((lank) => lank).map((lank) => ({ thang: lank.thang, sprite: lank })));
      return this.gameUIState.set('selected', selected);
    }

    onTreemaThangDoubleClicked(e, treema) {
      const {
        nativeEvent
      } = e.originalEvent;
      if (nativeEvent && (nativeEvent.ctrlKey || nativeEvent.metaKey)) { return; }
      const id = __guard__(treema != null ? treema.data : undefined, x => x.id);
      if (id) { return this.editThang({thangID: id}); }
    }

    getThangByID(id) { let left;
    return _.find((left = this.level.get('thangs')) != null ? left : [], {id}); }

    addThang(thangType, pos, batchInsert) {
      let components, thangID;
      if (batchInsert == null) { batchInsert = false; }
      this.$el.find('.generate-terrain-button').hide();
      if (batchInsert) {
        if (thangType.get('name') === 'Hero Placeholder') {
          thangID = 'Hero Placeholder';
          if (!this.level.isType('hero', 'hero-ladder', 'hero-coop', 'course', 'course-ladder', 'game-dev', 'web-dev') || this.getThangByID(thangID)) { return; }
        } else {
          thangID = `Random ${thangType.get('name')} ${this.thangsBatch.length}`;
        }
      } else {
        while (!thangID || !!this.getThangByID(thangID)) { thangID = Thang.nextID(thangType.get('name'), this.world); }
      }
      if (this.cloneSourceThang) {
        components = _.cloneDeep(this.getThangByID(this.cloneSourceThang.id).components);
      } else if (this.level.isType('hero', 'hero-ladder', 'hero-coop', 'course', 'course-ladder', 'game-dev', 'web-dev')) {
        components = [];  // Load them all from default ThangType Components
      } else {
        let left;
        components = _.cloneDeep((left = thangType.get('components')) != null ? left : []);
      }
      if (!components.length) { components = this.createEssentialComponents(thangType.get('components')); }
      if (utils.isCodeCombat) {
        const physical = _.find(components, c => (c.config != null ? c.config.pos : undefined) != null);
        if (physical) { physical.config.pos = {x: pos.x, y: pos.y, z: physical.config.pos.z}; }
      } else {
        const positionComponent = _.find(components || [], c => Array.from(LevelComponent.positionIDs).includes(c.original));
        if (positionComponent) {
          if (positionComponent.config == null) { positionComponent.config = {}; }
          positionComponent.config.pos = {x: pos.x, y: pos.y, z: __guard__(positionComponent.config != null ? positionComponent.config.pos : undefined, x => x.z) || 0};
        }
      }
      const thang = {thangType: thangType.get('original'), id: thangID, components};
      if (batchInsert) {
        this.thangsBatch.push(thang);
      }
      this.populateFoldersForThang(thang);
      return this.thangsTreema.set(this.pathForThang(thang), thang);
    }

    editThang(e) {
      let thangData;
      if (e.target) {  // click event
        thangData = $(e.target).data('thang-data');
      } else {  // Mediator event
        thangData = this.getThangByID(e.thangID);
      }
      if (!thangData) { return; }
      this.editThangView = new LevelThangEditView({thangData, level: this.level, world: this.world, supermodel: this.supermodel, oldPath: this.pathForThang(thangData)});  // supermodel needed for checkForMissingSystems
      this.insertSubView(this.editThangView);
      this.$el.find('>').hide();
      this.editThangView.$el.show();
      return Backbone.Mediator.publish('editor:view-switched', {});
    }

    onLevelThangDoneEditing(e) {
      this.removeSubView(this.editThangView);
      this.editThangView = null;
      this.updateEditedThang(e.thangData, e.oldPath);
      return this.$el.find('>').show();
    }

    onLevelThangEdited(e) {
      return this.updateEditedThang(e.thangData, e.oldPath);
    }

    updateEditedThang(newThang, oldPath) {
      if (!this.thangsTreema) { return; }
      if (_.isEqual(this.thangsTreema.get(oldPath), newThang)) { return; }
      this.hush = true;
      this.thangsTreema.delete(oldPath);
      this.populateFoldersForThang(newThang);
      this.thangsTreema.set(this.pathForThang(newThang), newThang);
      this.hush = false;
      return this.onThangsChanged();
    }

    preventDefaultContextMenu(e) {
      if (!$(e.target).closest('#canvas-wrapper').length) { return; }
      return e.preventDefault();
    }

    onSpriteContextMenu(e) {
      const {clientX, clientY} = e.originalEvent.nativeEvent;
      if (this.addThangType) {
        $('#duplicate a').html($.i18n.t('editor.stop_duplicate'));
      } else {
        $('#duplicate a').html($.i18n.t('editor.duplicate'));
      }
      $('#contextmenu').css({ position: 'fixed', left: clientX, top: clientY });
      return $('#contextmenu').show();
    }

    //- Context menu callbacks

    onDeleteClicked(e) {
      $('#contextmenu').hide();
      return this.deleteSelectedExtantThang(e);
    }

    onDuplicateClicked(e) {
      $('#contextmenu').hide();
      const selected = _.last(this.gameUIState.get('selected'));
      return this.selectAddThangType(selected.thang.spriteName, selected.thang);
    }

    onClickRotationButton(e) {
      $('#contextmenu').hide();
      const rotation = parseFloat($(e.target).closest('button').data('rotation'));
      return this.rotateSelectedThangTo(rotation * Math.PI);
    }

    modifySelectedThangComponentConfig(thang, componentOriginal, modificationFunction) {
      if (!thang) { return; }
      this.hush = true;
      let thangData = this.getThangByID(thang.id);
      thangData = $.extend(true, {}, thangData);
      let component = _.find(thangData.components, {original: componentOriginal});
      if (!component) {
        component = {original: componentOriginal, config: {}, majorVersion: 0};
        thangData.components.push(component);
      }
      modificationFunction(component);
      this.thangsTreema.set(this.pathForThang(thangData), thangData);
      this.hush = false;
      this.onThangsChanged(true);
      thang.stateChanged = true;
      const lank = this.surface.lankBoss.lanks[thang.id];
      lank.update(true);
      if (lank.marks.debug != null) {
        lank.marks.debug.destroy();
      }
      delete lank.marks.debug;
      return lank.setDebug(true);
    }

    getPID(selectedThang) {
      if (utils.isCodeCombat) {
        return LevelComponent.PhysicalID;
      } else {
        const positionComponent = _.find(this.getThangByID(selectedThang.id).components || [], c => Array.from(LevelComponent.positionIDs).includes(c.original));
        if (!positionComponent) { return undefined; }
        return positionComponent.original;
      }
    }

    rotateSelectedThangTo(radians) {
      return (() => {
        const result = [];
        for (var singleSelected of Array.from(this.gameUIState.get('selected'))) {
          var selectedThang = singleSelected.thang;
          var pid = this.getPID(selectedThang);
          if (!pid) { continue; }
          result.push(this.modifySelectedThangComponentConfig(selectedThang, pid, component => {
            component.config.rotation = radians;
            return selectedThang.rotation = component.config.rotation;
          }));
        }
        return result;
      })();
    }

    rotateSelectedThangBy(radians) {
      return (() => {
        const result = [];
        for (var singleSelected of Array.from(this.gameUIState.get('selected'))) {
          var selectedThang = singleSelected.thang;
          var pid = this.getPID(selectedThang);
          if (!pid) { continue; }
          result.push(this.modifySelectedThangComponentConfig(selectedThang, pid, component => {
            component.config.rotation = ((component.config.rotation != null ? component.config.rotation : 0) + radians) % (2 * Math.PI);
            return selectedThang.rotation = component.config.rotation;
          }));
        }
        return result;
      })();
    }

    moveSelectedThangBy(xDir, yDir) {
      return (() => {
        const result = [];
        for (var singleSelected of Array.from(this.gameUIState.get('selected'))) {
          var selectedThang = singleSelected.thang;
          var pid = this.getPID(selectedThang);
          if (!pid) { continue; }
          result.push(this.modifySelectedThangComponentConfig(selectedThang, pid, component => {
            component.config.pos.x += 0.5 * xDir;
            component.config.pos.y += 0.5 * yDir;
            selectedThang.pos.x = component.config.pos.x;
            return selectedThang.pos.y = component.config.pos.y;
          }));
        }
        return result;
      })();
    }

    resizeSelectedThangBy(xDir, yDir) {
      return (() => {
        const result = [];
        for (var singleSelected of Array.from(this.gameUIState.get('selected'))) {
          var pid;
          var selectedThang = singleSelected.thang;
          if (utils.isCodeCombat) {
            pid = LevelComponent.PhysicalID;
          } else {
            var shapeComponent = _.find(this.getThangByID(selectedThang.id).components || [], c => Array.from(LevelComponent.shapeIDs).includes(c.original));
            if (!shapeComponent) { continue; }
            pid = shapeComponent.original;
          }
          result.push(this.modifySelectedThangComponentConfig(selectedThang, pid, component => {
            component.config.width = (component.config.width != null ? component.config.width : 4) + (0.5 * xDir);
            component.config.height = (component.config.height != null ? component.config.height : 4) + (0.5 * yDir);
            selectedThang.width = component.config.width;
            return selectedThang.height = component.config.height;
          }));
        }
        return result;
      })();
    }

    toggleSelectedThangCollision() {
      return (() => {
        const result = [];
        for (var singleSelected of Array.from(this.gameUIState.get('selected'))) {
          var cid;
          var selectedThang = singleSelected.thang;
          if (utils.isCodeCombat) {
            cid = LevelComponent.CollidesID;
          } else {
            var collisionComponent = _.find(this.getThangByID(selectedThang.id).components || [], c => Array.from(LevelComponent.collisionIDs).includes(c.original));
            if (!collisionComponent) { continue; }
            cid = collisionComponent.original;
          }
          result.push(this.modifySelectedThangComponentConfig(selectedThang, cid, component => {
            if (component.config == null) { component.config = {}; }
            component.config.collisionCategory = component.config.collisionCategory === 'none' ? 'ground' : 'none';
            return selectedThang.collisionCategory = component.config.collisionCategory;
          }));
        }
        return result;
      })();
    }

    toggleThangsContainer(e) {
      return $('#all-thangs').toggleClass('hide');
    }

    toggleThangsPalette(e) {
      return $('#add-thangs-view').toggleClass('hide');
    }
  };
  ThangsTabView.initClass();
  return ThangsTabView;
})());

class ThangsFolderNode extends TreemaNode.nodeMap.object {
  static initClass() {
    this.prototype.valueClass = 'treema-thangs-folder';
    this.prototype.nodeDescription = 'Thang';
    this.nameToThangTypeMap = null;
  }

  getTrackedActionDescription(trackedAction) {
    let trackedActionDescription = super.getTrackedActionDescription(trackedAction);
    if (trackedActionDescription === ('Edit ' + this.nodeDescription)) {
      const path = trackedAction.path.split('/');
      if (path[path.length-1] === 'pos') {
        trackedActionDescription = 'Move Thang';
      }
    }
    return trackedActionDescription;
  }

  buildValueForDisplay(valEl, data) {
    const el = $(`<span><strong>${this.keyForParent}</strong> <span class='text-muted'>(${this.countThangs(data)})</span></span>`);

    // Kind of like having the portraits on the individual thang rows, rather than the parent folder row
    // but keeping this logic here in case we want to have it the other way.
//    if thangType = @nameToThangType(@keyForParent)
//      el.prepend($("<img class='img-circle' src='#{thangType.getPortraitURL()}' />"))
    return valEl.append(el);
  }

  countThangs(data) {
    if (data.thangType && (data.id != null)) { return 0; }
    let num = 0;
    for (var key in data) {
      var value = data[key];
      if (value.thangType && (value.id != null)) {
        num += 1;
      } else {
        num += this.countThangs(value);
      }
    }
    return num;
  }

  nameToThangType(name) {
    if (!ThangsFolderNode.nameToThangTypeMap) {
      const thangTypes = this.settings.supermodel.getModels(ThangType);
      const map = {};
      for (var thangType of Array.from(thangTypes)) { map[thangType.get('name')] = thangType; }
      ThangsFolderNode.nameToThangTypeMap = map;
    }
    return ThangsFolderNode.nameToThangTypeMap[name];
  }
}
ThangsFolderNode.initClass();

class ThangNode extends TreemaObjectNode {
  static initClass() {
    this.prototype.valueClass = 'treema-thang';
    this.prototype.collection = false;
    this.thangNameMap = {};
    this.thangKindMap = {};
  }
  buildValueForDisplay(valEl, data) {
    const pos = __guard__(_.find(data.components, c => (c.config != null ? c.config.pos : undefined) != null), x => x.config.pos);  // TODO: hack
    let s = data.id;
    if (pos) {
      s += ` (${Math.round(pos.x)}, ${Math.round(pos.y)})`;
    } else {
      s += ' (non-physical)';
    }
    this.buildValueForDisplaySimply(valEl, s);

    const thangType = this.settings.supermodel.getModelByOriginal(ThangType, data.thangType);
    if (thangType) {
      return valEl.prepend($(`<img class='img-circle' src='${thangType.getPortraitURL()}' />`));
    }
  }

  onEnterPressed() {
    return Backbone.Mediator.publish('editor:edit-level-thang', {thangID: this.getData().id});
  }
}
ThangNode.initClass();

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