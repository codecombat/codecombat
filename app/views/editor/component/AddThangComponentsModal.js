/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS104: Avoid inline assignments
 * DS204: Change includes calls to have a more natural evaluation order
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let UnnamedView;
require('app/styles/editor/component/add-thang-components-modal.sass');
const ModalView = require('views/core/ModalView');
const template = require('app/templates/editor/component/add-thang-components-modal');
const CocoCollection = require('collections/CocoCollection');
const LevelComponent = require('models/LevelComponent');

module.exports = (UnnamedView = (function() {
  UnnamedView = class UnnamedView extends ModalView {
    static initClass() {
      this.prototype.id = 'add-thang-components-modal';
      this.prototype.template = template;
      this.prototype.plain = true;
      this.prototype.modalWidthPercent = 80;
  
      this.prototype.events =
        {'click .footer button': 'onDonePressed'};
    }

    initialize(options) {
      super.initialize();
      this.skipOriginals = options.skipOriginals || [];
      this.components = new CocoCollection([], {model: LevelComponent});
      this.components.url = "/db/level.component?term=&archived=false&project=name,system,original,version,description";
      return this.supermodel.loadCollection(this.components, 'components');
    }

    getRenderData() {
      let comp;
      const c = super.getRenderData();
      c.components = ((() => {
        const result = [];
        for (comp of Array.from(this.components.models)) {           var needle;
        if (!((needle = comp.get('original'), Array.from(this.skipOriginals).includes(needle)))) {
            result.push(comp);
          }
        }
        return result;
      })());
      c.components = _.groupBy(c.components, comp => comp.get('system'));
      c.nameLists = {};
      for (var system in c.components) {
        var componentList = c.components[system];
        c.components[system] = _.sortBy(componentList, comp => comp.get('name'));
        c.nameLists[system] = ((() => {
          const result1 = [];
          for (comp of Array.from(c.components[system])) {             result1.push(comp.get('name'));
          }
          return result1;
        })()).join(', ');
      }
      c.systems = _.keys(c.components);
      c.systems.sort();
      return c;
    }

    getSelectedComponents() {
      const selected = this.$el.find('input[type="checkbox"]:checked');
      const vals = (Array.from(selected).map((el) => $(el).val()));
      const components = (Array.from(this.components.models).filter((c) => Array.from(vals).includes(c.id)));
      return components;
    }
  };
  UnnamedView.initClass();
  return UnnamedView;
})());
//    sparseComponents = ({original: c.get('original'), majorVersion: c.get('version').major} for c in components)
//    return sparseComponents
