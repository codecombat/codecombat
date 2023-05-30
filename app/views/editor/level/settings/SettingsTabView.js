// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS104: Avoid inline assignments
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let SettingsTabView;
require('app/styles/editor/level/settings_tab.sass');
const CocoView = require('views/core/CocoView');
const template = require('app/templates/editor/level/settings_tab');
const Level = require('models/Level');
const ThangType = require('models/ThangType');
const Surface = require('lib/surface/Surface');
const nodes = require('./../treema_nodes');
const {me} = require('core/auth');
require('lib/setupTreema');
const concepts = require('schemas/concepts');
const utils = require('core/utils');

module.exports = (SettingsTabView = (function() {
  SettingsTabView = class SettingsTabView extends CocoView {
    static initClass() {
      this.prototype.id = 'editor-level-settings-tab-view';
      this.prototype.className = 'tab-pane';
      this.prototype.template = template;
  
      this.prototype.subscriptions = {
        'editor:level-loaded': 'onLevelLoaded',
        'editor:thangs-edited': 'onThangsEdited',
        'editor:random-terrain-generated': 'onRandomTerrainGenerated'
      };
  
      // Not thangs or scripts or the backend stuff. Most properties will be added from the schema inEditor field.
      this.prototype.editableSettings = ['name'];
    }

    constructor(options) {
      this.onSettingsChanged = this.onSettingsChanged.bind(this);
      super(options);
      this.editableSettings = this.editableSettings.concat(_.keys(_.pick(Level.schema.properties, (value, key) => (value.inEditor === true) || (value.inEditor === utils.getProduct()))));
    }

    onLoaded() {}
    onLevelLoaded(e) {
      this.level = e.level;
      const data = _.pick(this.level.attributes, (value, key) => Array.from(this.editableSettings).includes(key));
      const schema = _.cloneDeep(Level.schema);
      schema.properties = _.pick(schema.properties, (value, key) => Array.from(this.editableSettings).includes(key));
      schema.required = _.intersection(schema.required, this.editableSettings);
      schema.default = _.pick(schema.default, (value, key) => Array.from(this.editableSettings).includes(key));
      this.thangIDs = this.getThangIDs();
      const treemaOptions = {
        filePath: `db/level/${this.level.get('original')}`,
        supermodel: this.supermodel,
        schema,
        data,
        readOnly: me.get('anonymous'),
        callbacks: {change: this.onSettingsChanged},
        thangIDs: this.thangIDs,
        nodeClasses: {
          object: SettingsNode,
          thang: nodes.ThangNode,
          'solution-gear': SolutionGearNode,
          'solution-stats': SolutionStatsNode,
          concept: ConceptNode,
          'concepts-list': ConceptsListNode,
          'clans-list': ClansListNode
        },
        solutions: this.level.getSolutions()
      };

      this.settingsTreema = this.$el.find('#settings-treema').treema(treemaOptions);
      this.settingsTreema.build();
      this.settingsTreema.open();
      this.lastTerrain = data.terrain;
      return this.lastType = data.type;
    }

    getThangIDs() {
      let left;
      return (Array.from((left = this.level.get('thangs')) != null ? left : []).map((t) => t.id));
    }

    onSettingsChanged(e) {
      let terrain, type;
      $('.level-title').text(this.settingsTreema.data.name);
      for (var key of Array.from(this.editableSettings)) {
        this.level.set(key, this.settingsTreema.data[key]);
      }
      if ((terrain = this.settingsTreema.data.terrain) !== this.lastTerrain) {
        this.lastTerrain = terrain;
        Backbone.Mediator.publish('editor:terrain-changed', {terrain});
      }
      if ((type = this.settingsTreema.data.type) !== this.lastType) {
        this.onTypeChanged(type);
      }
      return (() => {
        const result = [];
        const iterable = this.settingsTreema.data.goals != null ? this.settingsTreema.data.goals : [];
        for (let index = 0; index < iterable.length; index++) {
          var goal = iterable[index];
          if (goal.id) { continue; }
          var goalIndex = index;
          var goalID = `goal-${goalIndex}`;
          while (_.find(this.settingsTreema.get("goals"), {id: goalID})) { goalID = `goal-${++goalIndex}`; }
          this.settingsTreema.disableTracking();
          this.settingsTreema.set(`/goals/${index}/id`, goalID);
          this.settingsTreema.set(`/goals/${index}/name`, _.string.humanize(goalID));
          result.push(this.settingsTreema.enableTracking());
        }
        return result;
      })();
    }

    onThangsEdited(e) {
      // Update in-place so existing Treema nodes refer to the same array.
      if (this.thangIDs != null) {
        this.thangIDs.splice(0, this.thangIDs.length, ...Array.from(this.getThangIDs()));
      }
      return this.settingsTreema.solutions = this.level.getSolutions();  // Remove if slow
    }

    onRandomTerrainGenerated(e) {
      return this.settingsTreema.set('/terrain', e.terrain);
    }

    onTypeChanged(type) {
      this.lastType = type;
      if ((type === 'ladder') && (this.settingsTreema.get('/mirrorMatch') !== false)) {
        this.settingsTreema.set('/mirrorMatch', false);
        return noty({
          text: "Type updated to 'ladder', so mirrorMatch has been updated to false.",
          layout: 'topCenter',
          timeout: 5000,
          type: 'information'
        });
      }
    }

    destroy() {
      if (this.settingsTreema != null) {
        this.settingsTreema.destroy();
      }
      return super.destroy();
    }
  };
  SettingsTabView.initClass();
  return SettingsTabView;
})());


class SettingsNode extends TreemaObjectNode {
  static initClass() {
    this.prototype.nodeDescription = 'Settings';
  }
}
SettingsNode.initClass();

class SolutionGearNode extends TreemaArrayNode {
  select() {
    let solution;
    let prop;
    super.select();
    if (!(solution = _.find(this.getRoot().solutions, {succeeds: true, language: 'javascript'}))) { return; }
    const propertiesUsed = [];
    for (var match of Array.from((solution.source != null ? solution.source : '').match(/hero\.([a-z][A-Za-z0-9]*)/g))) {
      prop = match.split('.')[1];
      if (!Array.from(propertiesUsed).includes(prop)) { propertiesUsed.push(prop); }
    }
    if (!propertiesUsed.length) { return; }
    if (_.isEqual(this.data, propertiesUsed)) {
      this.$el.find('.treema-description').html('Solution uses exactly these required properties.');
      return;
    }
    const description = 'Solution used properties: ' + [(() => {
      const result = [];
      for (prop of Array.from(propertiesUsed)) {         result.push(`<code>${prop}</code>`);
      }
      return result;
    })()].join(' ');
    const button = $('<button class="btn btn-sm">Use</button>');
    $(button).on('click', () => {
      this.set('', propertiesUsed);
      return _.defer(() => {
        this.open();
        return this.select();
      });
    });
    return this.$el.find('.treema-description').html(description).append(button);
  }
}

class SolutionStatsNode extends TreemaNode.nodeMap.number {
  select() {
    let solution;
    super.select();
    if (!(solution = _.find(this.getRoot().solutions, {succeeds: true, language: 'javascript'}))) { return; }
    return ThangType.calculateStatsForHeroConfig(solution.heroConfig, stats => {
      for (var key in stats) { var val = stats[key]; if (parseInt(val) !== val) { stats[key] = val.toFixed(2); } }
      const description = `Solution had stats: <code>${JSON.stringify(stats)}</code>`;
      const button = $('<button class="btn btn-sm">Use health</button>');
      $(button).on('click', () => {
        this.set('', stats.health);
        return _.defer(() => {
          this.open();
          return this.select();
        });
      });
      return this.$el.find('.treema-description').html(description).append(button);
    });
  }
}

class ConceptNode extends TreemaNode.nodeMap.string {
  buildValueForDisplay(valEl, data) {
    let concept;
    super.buildValueForDisplay(valEl, data);
    if (!data) { return; }
    if (!(concept = _.find(concepts, {concept: this.data}))) { return console.error(`Couldn't find concept ${this.data}`); }
    let description = `${concept.name} -- ${concept.description}`;
    if (concept.deprecated) { description = description + " (Deprecated)"; }
    if (concept.automatic) { description = "AUTO | " + description; }
    this.$el.find('.treema-row').css('float', 'left');
    if (concept.automatic) { this.$el.addClass('concept-automatic'); }
    if (concept.deprecated) { this.$el.addClass('concept-deprecated'); }
    this.$el.find('.treema-description').remove();
    return this.$el.append($(`<span class='treema-description'>${description}</span>`).show());
  }

  limitChoices(options) {
    let o, c;
    if ((this.parent.keyForParent === 'concepts') && (!this.parent.parent)) {
      options = ((() => {
        const result = [];
        for (o of Array.from(options)) {           if (_.find(concepts, c => (c.concept === o) && !c.automatic && !c.deprecated)) {
            result.push(o);
          }
        }
        return result;
      })());  // Allow manual, not automatic
    } else {
      options = ((() => {
        const result1 = [];
        for (o of Array.from(options)) {           if (_.find(concepts, c => (c.concept === o) && !c.deprecated)) {
            result1.push(o);
          }
        }
        return result1;
      })());  // Allow both
    }
    return super.limitChoices(options);
  }

  onClick(e) {
    if ((this.parent.keyForParent === 'concepts') && (!this.parent.parent) && this.$el.hasClass('concept-automatic')) { return; }  // Don't allow editing of automatic concepts
    return super.onClick(e);
  }
}

class ConceptsListNode extends TreemaNode.nodeMap.array {
  static initClass() {
    this.prototype.sort = true;
  }

  sortFunction(a, b) {
    const aAutomatic = _.find(concepts, c => (c.concept === a) && c.automatic);
    const bAutomatic = _.find(concepts, c => (c.concept === b) && c.automatic);
    if (bAutomatic && !aAutomatic) { return 1; }  // Auto before manual
    if (aAutomatic && !bAutomatic) { return -1; }  // Auto before manual
    if (!aAutomatic && !bAutomatic) { return 0; }  // No ordering within manual
    return super.sortFunction(a, b);
  }
}
ConceptsListNode.initClass();  // Alpha within auto

class ClansListNode extends TreemaNode.nodeMap.array {
  static initClass() {
    this.prototype.nodeDescription = 'ClansList';
  }
}
ClansListNode.initClass();
