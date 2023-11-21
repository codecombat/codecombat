// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS104: Avoid inline assignments
 * DS202: Simplify dynamic range loops
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ComponentsTabView;
require('app/styles/editor/level/components_tab.sass');
const CocoView = require('views/core/CocoView');
const template = require('app/templates/editor/level/components_tab');
const ThangType = require('models/ThangType');
const LevelComponent = require('models/LevelComponent');
const LevelComponentEditView = require('./LevelComponentEditView');
const LevelComponentNewView = require('./NewLevelComponentModal');
require('lib/setupTreema');

class LevelComponentCollection extends Backbone.Collection {
  static initClass() {
    this.prototype.url = '/db/level.component';
    this.prototype.model = LevelComponent;
  }
}
LevelComponentCollection.initClass();

module.exports = (ComponentsTabView = (function() {
  ComponentsTabView = class ComponentsTabView extends CocoView {
    constructor(...args) {
      super(...args);
      this.onTreemaComponentSelected = this.onTreemaComponentSelected.bind(this);
    }

    static initClass() {
      this.prototype.id = 'editor-level-components-tab-view';
      this.prototype.template = template;
      this.prototype.className = 'tab-pane';

      this.prototype.subscriptions = {
        'editor:level-component-editing-ended': 'onLevelComponentEditingEnded',
        'editor:level-loaded': 'onLevelLoaded'
      };

      this.prototype.events = {
        'click #create-new-component-button': 'createNewLevelComponent',
        'click #create-new-component-button-no-select': 'createNewLevelComponent'
      };
    }

    onLoaded() {}

    onLevelLoaded(e) {
      return this.level = e.level;
    }

    refreshLevelThangsTreema(thangsData) {
      let component;
      let asc, end;
      let key, value;
      const presentComponents = {};
      for (var thang of Array.from(thangsData)) {
        var left;
        var componentMap = {};
        var thangType = this.supermodel.getModelByOriginal(ThangType, thang.thangType);
        for (component of Array.from((left = thangType.get('components')) != null ? left : [])) {
          componentMap[component.original] = component;
        }

        for (component of Array.from(thang.components)) {
          componentMap[component.original] = component;
        }

        for (component of Array.from(_.values(componentMap))) {
          var name;
          var haveThisComponent = (presentComponents[name = component.original + '.' + (component.majorVersion != null ? component.majorVersion : 0)] != null ? presentComponents[name] : (presentComponents[name] = []));
          if (haveThisComponent.length < 100) { haveThisComponent.push(thang.id); }
        }
      }  // for performance when adding many Thangs
      if (_.isEqual(presentComponents, this.presentComponents)) { return; }
      this.presentComponents = presentComponents;

      const componentModels = this.supermodel.getModels(LevelComponent);
      const componentModelMap = {};
      for (var comp of Array.from(componentModels)) { componentModelMap[comp.get('original')] = comp; }
      let components = ((() => {
        const result = [];
        for (key in this.presentComponents) {
          value = this.presentComponents[key];
          result.push({original: key.split('.')[0], majorVersion: parseInt(key.split('.')[1], 10), thangs: value, count: value.length});
        }
        return result;
      })());
      components = components.concat(((() => {
        const result1 = [];
        for (var c of Array.from(componentModels)) {           if (!this.presentComponents[c.get('original') + '.' + c.get('version').major]) {
            result1.push({original: c.get('original'), majorVersion: c.get('version').major, thangs: [], count: 0});
          }
        }
        return result1;
      })()));
      let treemaData = _.sortBy(components, comp => {
        component = componentModelMap[comp.original];
        const res = [(comp.count ? 0 : 1), component.get('system'), component.get('name')];
        return res;
      });

      const res = {};
      for (key = 0, end = treemaData.length, asc = 0 <= end; asc ? key < end : key > end; asc ? key++ : key--) { res[treemaData[key].original] = treemaData[key]; }
      treemaData = ((() => {
        const result2 = [];
        for (key in res) {
          value = res[key];
          result2.push(value);
        }
        return result2;
      })());  // Removing duplicates from treemaData

      const treemaOptions = {
        supermodel: this.supermodel,
        schema: {type: 'array', items: {type: 'object', format: 'level-component'}},
        data: treemaData,
        callbacks: {
          select: this.onTreemaComponentSelected
        },
        readOnly: true,
        nodeClasses: {'level-component': LevelComponentNode}
      };
      this.componentsTreema = this.$el.find('#components-treema').treema(treemaOptions);
      this.componentsTreema.build();
      return this.componentsTreema.open();
    }

    onTreemaComponentSelected(e, selected) {
      selected = selected.length > 1 ? selected[0].getLastSelectedTreema() : selected[0];
      if (!selected) {
        this.removeSubView(this.levelComponentEditView);
        this.levelComponentEditView = null;
        return;
      }

      return this.editLevelComponent({original: selected.data.original, majorVersion: selected.data.majorVersion});
    }

    createNewLevelComponent(e) {
      const levelComponentNewView = new LevelComponentNewView({supermodel: this.supermodel});
      this.openModalView(levelComponentNewView);
      return Backbone.Mediator.publish('editor:view-switched', {});
    }

    editLevelComponent(e) {
      return this.levelComponentEditView = this.insertSubView(new LevelComponentEditView({original: e.original, majorVersion: e.majorVersion, supermodel: this.supermodel, filePath: `db/level/${this.level.get('original')}`}));
    }

    onLevelComponentEditingEnded(e) {
      this.removeSubView(this.levelComponentEditView);
      return this.levelComponentEditView = null;
    }

    destroy() {
      if (this.componentsTreema != null) {
        this.componentsTreema.destroy();
      }
      return super.destroy();
    }
  };
  ComponentsTabView.initClass();
  return ComponentsTabView;
})());

class LevelComponentNode extends TreemaObjectNode {
  static initClass() {
    this.prototype.valueClass = 'treema-level-component';
    this.prototype.collection = false;
  }
  buildValueForDisplay(valEl, data) {
    let name;
    const count = data.count === 1 ? data.thangs[0] : ((data.count >= 100 ? '100+' : data.count) + ' Thangs');
    if (data.original.match(':')) {
      name = 'Old: ' + data.original.replace('systems/', '');
    } else {
      const comp = _.find(this.settings.supermodel.getModels(LevelComponent), m => {
        return (m.get('original') === data.original) && (m.get('version').major === data.majorVersion);
      });
      name = `${comp.get('system')}.${comp.get('name')} v${comp.get('version').major}`;
    }
    const result = this.buildValueForDisplaySimply(valEl, `${name} (${count})`);
    if (!data.count) { result.addClass('not-present'); }
    return result;
  }
}
LevelComponentNode.initClass();
