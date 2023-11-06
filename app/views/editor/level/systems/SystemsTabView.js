// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let SystemsTabView;
require('app/styles/editor/level/systems-tab-view.sass');
const CocoView = require('views/core/CocoView');
const template = require('app/templates/editor/level/systems-tab-view');
const Level = require('models/Level');
const LevelSystem = require('models/LevelSystem');
const LevelSystemEditView = require('./LevelSystemEditView');
const NewLevelSystemModal = require('./NewLevelSystemModal');
const AddLevelSystemModal = require('./AddLevelSystemModal');
const nodes = require('../treema_nodes');
require('lib/setupTreema');

module.exports = (SystemsTabView = (function() {
  SystemsTabView = class SystemsTabView extends CocoView {
    static initClass() {
      this.prototype.id = 'systems-tab-view';
      this.prototype.template = template;
      this.prototype.className = 'tab-pane';

      this.prototype.subscriptions = {
        'editor:level-system-added': 'onLevelSystemAdded',
        'editor:edit-level-system': 'editLevelSystem',
        'editor:level-system-editing-ended': 'onLevelSystemEditingEnded',
        'editor:level-loaded': 'onLevelLoaded',
        'editor:terrain-changed': 'onTerrainChanged'
      };

      this.prototype.events = {
        'click #add-system-button': 'addLevelSystem',
        'click #create-new-system-button': 'createNewLevelSystem',
        'click #create-new-system': 'createNewLevelSystem'
      };
    }

    constructor(options) {
      super(options);
      this.onSystemsChanged = this.onSystemsChanged.bind(this);
      this.getSortedByName = this.getSortedByName.bind(this);
      this.onSystemSelected = this.onSystemSelected.bind(this);
      for (var system of Array.from(this.buildDefaultSystems())) {
        var url = `/db/level.system/${system.original}/version/${system.majorVersion}`;
        var ls = new LevelSystem().setURL(url);
        this.supermodel.loadModel(ls);
      }
    }

    afterRender() {
      return this.buildSystemsTreema();
    }

    onLoaded() {
      return super.onLoaded();
    }

    onLevelLoaded(e) {
      this.level = e.level;
      return this.buildSystemsTreema();
    }

    buildSystemsTreema() {
      let insertedDefaults, left;
      if (!this.level || !this.supermodel.finished()) { return; }
      let systems = $.extend(true, [], (left = this.level.get('systems')) != null ? left : []);
      if (!systems.length) {
        systems = this.buildDefaultSystems();
        insertedDefaults = true;
      }
      systems = this.getSortedByName(systems);
      const thangs = (this.level != null) ? this.level.get('thangs') : [];
      const thangIDs = _.filter(_.pluck(thangs, 'id'));
      const teams = _.filter(_.pluck(thangs, 'team'));
      let superteams = _.filter(_.pluck(thangs, 'superteam'));
      superteams = _.union(teams, superteams);
      const treemaOptions = {
        supermodel: this.supermodel,
        schema: Level.schema.properties.systems,
        data: systems,
        readOnly: me.get('anonymous'),
        world: this.options.world,
        view: this,
        thangIDs,
        teams,
        superteams,
        callbacks: {
          change: this.onSystemsChanged,
          select: this.onSystemSelected
        },
        nodeClasses: {
          'level-system': LevelSystemNode,
          'level-system-configuration': LevelSystemConfigurationNode,
          'point2d': nodes.WorldPointNode,
          'viewport': nodes.WorldViewportNode,
          'bounds': nodes.WorldBoundsNode,
          'radians': nodes.RadiansNode,
          'team': nodes.TeamNode,
          'superteam': nodes.SuperteamNode,
          'meters': nodes.MetersNode,
          'kilograms': nodes.KilogramsNode,
          'seconds': nodes.SecondsNode,
          'speed': nodes.SpeedNode,
          'acceleration': nodes.AccelerationNode,
          'thang-type': nodes.ThangTypeNode,
          'item-thang-type': nodes.ItemThangTypeNode
        }
      };

      this.systemsTreema = this.$el.find('#systems-treema').treema(treemaOptions);
      this.systemsTreema.build();
      this.systemsTreema.open();
      if (insertedDefaults) { return this.onSystemsChanged(); }
    }

    onSystemsChanged(e) {
      const systems = this.getSortedByName(this.systemsTreema.data);
      return this.level.set('systems', systems);
    }

    getSortedByName(systems) {
      const systemModels = this.supermodel.getModels(LevelSystem);
      const systemModelMap = {};
      for (var sys of Array.from(systemModels)) { systemModelMap[sys.get('original')] = sys.get('name'); }
      return _.sortBy(systems, sys => systemModelMap[sys.original]);
    }

    onSystemSelected(e, selected) {
      let data;
      selected = selected.length > 1 ? selected[0].getLastSelectedTreema() : selected[0];
      if (!selected) {
        if (this.levelSystemEditView) { this.removeSubView(this.levelSystemEditView); }
        this.levelSystemEditView = null;
        return;
      }
      while ((!(data = selected.getData())) || !data.original) {
        selected = selected.parent;
      }
      return this.editLevelSystem({original: data.original, majorVersion: data.majorVersion});
    }

    onLevelSystemAdded(e) {
      return this.systemsTreema.insert('/', e.system);
    }

    addLevelSystem(e) {
      this.openModalView(new AddLevelSystemModal({supermodel: this.supermodel, extantSystems: _.cloneDeep(this.systemsTreema.data)}));
      return Backbone.Mediator.publish('editor:view-switched', {});
    }

    createNewLevelSystem(e) {
      this.openModalView(new NewLevelSystemModal({supermodel: this.supermodel}));
      return Backbone.Mediator.publish('editor:view-switched', {});
    }

    editLevelSystem(e) {
      return this.levelSystemEditView = this.insertSubView(new LevelSystemEditView({original: e.original, majorVersion: e.majorVersion, supermodel: this.supermodel, filePath: `db/level/${this.level.get('original')}`}));
    }

    onLevelSystemEditingEnded(e) {
      this.removeSubView(this.levelSystemEditView);
      return this.levelSystemEditView = null;
    }

    onTerrainChanged(e) {
      let AI, Vision;
      const defaultPathfinding = ['Dungeon', 'Indoor', 'Mountain', 'Glacier', 'Volcano'].includes(e.terrain);
      let changed = false;
      if (AI = this.systemsTreema.get('original=528110f30268d018e3000001')) {
        if ((AI.config != null ? AI.config.findsPaths : undefined) !== defaultPathfinding) {
          if (AI.config == null) { AI.config = {}; }
          AI.config.findsPaths = defaultPathfinding;
          this.systemsTreema.set('original=528110f30268d018e3000001', AI);
          changed = true;
        }
      }
      if (Vision = this.systemsTreema.get('original=528115040268d018e300001b')) {
        if ((Vision.config != null ? Vision.config.checksLineOfSight : undefined) !== defaultPathfinding) {
          if (Vision.config == null) { Vision.config = {}; }
          Vision.config.checksLineOfSight = defaultPathfinding;
          this.systemsTreema.set('original=528115040268d018e300001b', Vision);
          changed = true;
        }
      }
      if (changed) {
        return noty({
          text: `AI/Vision System defaulted pathfinding/line-of-sight to ${defaultPathfinding} for terrain ${e.terrain}.`,
          layout: 'topCenter',
          timeout: 5000,
          type: 'information'
        });
      }
    }

    buildDefaultSystems() {
      return [
        {original: '528112c00268d018e3000008', majorVersion: 0},  // Event
        {original: '5280f83b8ae1581b66000001', majorVersion: 0},  // Existence
        {original: '5281146f0268d018e3000014', majorVersion: 0},  // Programming
        {original: '528110f30268d018e3000001', majorVersion: 0},  // AI
        {original: '52810ffa33e01a6e86000012', majorVersion: 0},  // Action
        {original: '528114b20268d018e3000017', majorVersion: 0},  // Targeting
        {original: '528105f833e01a6e86000007', majorVersion: 0},  // Collision
        {original: '528113240268d018e300000c', majorVersion: 0},  // Movement
        {original: '528112530268d018e3000007', majorVersion: 0},  // Combat
        {original: '52810f4933e01a6e8600000c', majorVersion: 0},  // Hearing
        {original: '528115040268d018e300001b', majorVersion: 0},  // Vision
        {original: '5280dc4d251616c907000001', majorVersion: 0},  // Inventory
        {original: '528111b30268d018e3000004', majorVersion: 0},  // Alliance
        {original: '528114e60268d018e300001a', majorVersion: 0},  // UI
        {original: '528114040268d018e3000011', majorVersion: 0},  // Physics
        {original: '52ae4f02a4dcd4415200000b', majorVersion: 0},  // Display
        {original: '52e953e81b2028d102000004', majorVersion: 0},  // Effect
        {original: '52f1354370fb890000000005', majorVersion: 0}  // Magic
      ];
    }

    destroy() {
      if (this.systemsTreema != null) {
        this.systemsTreema.destroy();
      }
      return super.destroy();
    }
  };
  SystemsTabView.initClass();
  return SystemsTabView;
})());

class LevelSystemNode extends TreemaObjectNode {
  static initClass() {
    this.prototype.valueClass = 'treema-level-system';
  }
  constructor() {
    super(...arguments);
    this.grabDBComponent();
    this.collection = (__guard__(__guard__(this.system != null ? this.system.attributes : undefined, x1 => x1.configSchema), x => x.properties) != null);
  }

  grabDBComponent() {
    const data = this.getData();
    this.system = this.settings.supermodel.getModelByOriginalAndMajorVersion(LevelSystem, data.original, data.majorVersion);
    if (!this.system) { return console.error('Couldn\'t find system for', data.original, data.majorVersion, 'from models', this.settings.supermodel.models); }
  }

  getChildSchema(key) {
    if (key === 'config') { return this.system.attributes.configSchema; }
    return super.getChildSchema(key);
  }

  buildValueForDisplay(valEl, data) {
    if (!data.original || !this.system) { return super.buildValueForDisplay(valEl); }
    let name = this.system.get('name');
    if (this.system.get('version').major) { name += ` v${this.system.get('version').major}`; }
    return this.buildValueForDisplaySimply(valEl, name);
  }

  onEnterPressed(e) {
    super.onEnterPressed(e);
    const data = this.getData();
    return Backbone.Mediator.publish('editor:edit-level-system', {original: data.original, majorVersion: data.majorVersion});
  }

  open(depth) {
    super.open(depth);
    const cTreema = this.childrenTreemas.config;
    if ((cTreema != null) && (cTreema.getChildren().length || cTreema.canAddChild())) {
      return cTreema.open();
    }
  }
}
LevelSystemNode.initClass();
// No easy way to flatten the config object, so for now just keep it longer than it needs to be

class LevelSystemConfigurationNode extends TreemaObjectNode {
  static initClass() {
    this.prototype.valueClass = 'treema-level-system-configuration';
  }
  buildValueForDisplay() {  }
}
LevelSystemConfigurationNode.initClass();

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}