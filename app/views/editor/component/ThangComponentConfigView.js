// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ThangComponentConfigView;
const CocoView = require('views/core/CocoView');
const template = require('app/templates/editor/component/thang-component-config-view');
const utils = require('core/utils');

const Level = require('models/Level');
const LevelComponent = require('models/LevelComponent');
const nodes = require('../level/treema_nodes');
require('lib/setupTreema');

module.exports = (ThangComponentConfigView = (function() {
  ThangComponentConfigView = class ThangComponentConfigView extends CocoView {
    static initClass() {
      this.prototype.className = 'thang-component-config-view';
      this.prototype.template = template;
      this.prototype.changed = false;
    }

    constructor(options) {
      super(options);
      this.onConfigEdited = this.onConfigEdited.bind(this);
      this.component = options.component;
      this.config = options.config || {};
      this.additionalDefaults = options.additionalDefaults;
      this.isDefaultComponent = false;
      this.world = options.world;
      this.level = options.level;
      this.callback = options.callback;
    }

    afterRender() {
      super.afterRender();
      return this.buildTreema();
    }

    setConfig(config) {
      this.config = config;
      this.handlingChange = true;
      this.editThangTreema.set('/', this.config);
      return this.handlingChange = false;
    }

    setIsDefaultComponent(isDefaultComponent) {
      const changed = this.isDefaultComponent !== isDefaultComponent;
      if (isDefaultComponent) { this.config = undefined; }
      this.isDefaultComponent = isDefaultComponent;
      if (changed) { return this.render(); }
    }

    buildTreema() {
      const thangs = (this.level != null) ? this.level.get('thangs') : [];
      const thangIDs = _.filter(_.pluck(thangs, 'id'));
      const teams = _.filter(_.pluck(thangs, 'team'));
      let superteams = _.filter(_.pluck(thangs, 'superteam'));
      superteams = _.union(teams, superteams);
      const schema = $.extend(true, {}, this.component.get('configSchema'));
      if (schema.default == null) { schema.default = {}; }
      if (this.additionalDefaults) { _.merge(schema.default, this.additionalDefaults); }

      if (utils.isCodeCombat || (this.level != null ? this.level.isType('hero', 'hero-ladder', 'hero-coop', 'course', 'course-ladder', 'game-dev', 'web-dev') : undefined)) {
        schema.required = [];
      }
      const treemaOptions = {
        supermodel: this.supermodel,
        schema,
        data: this.config,
        callbacks: {change: this.onConfigEdited},
        world: this.world,
        view: this,
        thangIDs,
        teams,
        superteams,
        nodeClasses: {
          object: ComponentConfigNode,
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
          'item-thang-type': nodes.ItemThangTypeNode,
          'solutions': SolutionsNode
        }
      };

      this.editThangTreema = this.$el.find('.treema').treema(treemaOptions);
      this.editThangTreema.build();
      this.editThangTreema.open(2);
      this.openTastyTreemas();
      if (_.isEqual(this.editThangTreema.data, {}) && !this.editThangTreema.canAddChild()) {
        return this.$el.find('.panel-body').hide();
      }
    }

    onConfigEdited() {
      if (this.destroyed || this.handlingChange) { return; }
      this.config = this.data();
      this.changed = true;
      return this.trigger('changed', { component: this.component, config: this.config });
    }

    data() { return this.editThangTreema.data; }

    destroy() {
      if (this.editThangTreema != null) {
        this.editThangTreema.destroy();
      }
      return super.destroy();
    }

    openTastyTreemas() {
      // To save on quick inspection, let's auto-open the properties we're most likely to want to see.
      const delicacies = [
        ['programmableMethods', 'plan', 'languages']
      ];
      return (() => {
        const result = [];
        for (var dish of Array.from(delicacies)) {
          var node = this.editThangTreema;
          result.push((() => {
            const result1 = [];
            for (var ingredient of Array.from(dish)) {
              var child;
              if (!(child = node.childrenTreemas != null ? node.childrenTreemas[ingredient] : undefined)) { continue; }
              child.open();
              result1.push(node = child);
            }
            return result1;
          })());
        }
        return result;
      })();
    }
  };
  ThangComponentConfigView.initClass();
  return ThangComponentConfigView;
})());

class ComponentConfigNode extends TreemaObjectNode {
  static initClass() {
    this.prototype.nodeDescription = 'Component Property';
  }
}
ComponentConfigNode.initClass();

class SolutionsNode extends TreemaArrayNode {
  constructor(...args) {
    this.onClickFillDefaults = this.onClickFillDefaults.bind(this);
    super(...args);
  }

  buildValueForDisplay(valEl, data) {
    const btn = $('<button class="btn btn-default btn-xs">Fill defaults</button>');
    btn.on('click', this.onClickFillDefaults);
    return valEl.append(btn);
  }

  onClickFillDefaults(e) {
    e.preventDefault();

    const sources = { javascript: this.parent.data.source };
    _.extend(sources, this.parent.data.languages || {});
    let solutions = _.clone(this.data);
    solutions = _.filter(solutions, solution => !_.isEmpty(solution));
    for (var language of Array.from(_.keys(sources))) {
      var source = sources[language];
      var solution = _.findWhere(solutions, {language});
      if (solution) { continue; }
      solutions.push({
        source,
        language,
        succeeds: true
      });
    }

    return this.set('/', solutions);
  }
}
