// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS104: Avoid inline assignments
 * DS204: Change includes calls to have a more natural evaluation order
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ThangComponentsEditView;
require('app/styles/editor/component/thang-components-edit-view.sass');
const CocoView = require('views/core/CocoView');
const template = require('app/templates/editor/component/thang-components-edit-view');

const Level = require('models/Level');
const LevelComponent = require('models/LevelComponent');
const LevelSystem = require('models/LevelSystem');
const LevelComponents = require('collections/LevelComponents');
const ThangComponentConfigView = require('./ThangComponentConfigView');
const AddThangComponentsModal = require('./AddThangComponentsModal');
const nodes = require('../level/treema_nodes');
require('lib/setupTreema');
const utils = require('core/utils');

const ThangType = require('models/ThangType');
const CocoCollection = require('collections/CocoCollection');

const LC = (componentName, config) => ({
  original: LevelComponent[componentName + 'ID'],
  majorVersion: 0,
  config
});
const DEFAULT_COMPONENTS = {
  Unit: [LC('Equips'), LC('FindsPaths')],
  Hero: [LC('Equips'), LC('FindsPaths')],
  Floor: [
    LC('Exists', {stateless: true}),
    LC('Physical', {width: 20, height: 17, depth: 2, shape: 'sheet', pos: {x: 10, y: 8.5, z: 1}}),
    LC('Land')
  ],
  Wall: [
    LC('Exists', {stateless: true}),
    LC('Physical', {width: 4, height: 4, depth: 12, shape: 'box', pos: {x: 2, y: 2, z: 6}}),
    LC('Collides', {collisionType: 'static', collisionCategory: 'obstacles', mass: 1000, fixedRotation: true, restitution: 1})
  ],
  Doodad: [
    LC('Exists', {stateless: true}),
    LC('Physical'),
    LC('Collides', {collisionType: 'static', fixedRotation: true})
  ],
  Misc: [LC('Exists'), LC('Physical')],
  Mark: [],
  Item: [LC('Item')],
  Missile: [LC('Missile')]
};

module.exports = (ThangComponentsEditView = (function() {
  ThangComponentsEditView = class ThangComponentsEditView extends CocoView {
    static initClass() {
      this.prototype.id = 'thang-components-edit-view';
      this.prototype.template = template;

      this.prototype.subscriptions =
        {'editor:thang-type-kind-changed': 'onThangTypeKindChanged'};

      this.prototype.events =
        {'click #add-components-button': 'onAddComponentsButtonClicked'};
    }

    constructor(options) {
      super(options);
      this.onComponentsTreemaChanged = this.onComponentsTreemaChanged.bind(this);
      this.onComponentsChanged = this.onComponentsChanged.bind(this);
      this.onSelectComponent = this.onSelectComponent.bind(this);
      this.onChangeExtantComponents = this.onChangeExtantComponents.bind(this);
      this.originalsLoaded = {};
      this.components = options.components || [];
      this.components = $.extend(true, [], this.components); // just to be sure
      this.setThangType(options.thangType);
      this.lastComponentLength = this.components.length;
      this.world = options.world;
      this.level = options.level;
      this.loadComponents(this.components);
    }

    setThangType(thangType) {
      let componentRefs;
      this.thangType = thangType;
      if (!(componentRefs = this.thangType != null ? this.thangType.get('components') : undefined)) { return; }
      return this.loadComponents(componentRefs);
    }

    loadComponents(components) {
      return (() => {
        const result = [];
        for (var componentRef of Array.from(components)) {
        // just to handle if ever somehow the same component is loaded twice, through bad data and alike
          if (this.originalsLoaded[componentRef.original]) { continue; }
          this.originalsLoaded[componentRef.original] = componentRef.original;

          var levelComponent = new LevelComponent(componentRef);
          var url = `/db/level.component/${componentRef.original}/version/${componentRef.majorVersion}`;
          levelComponent.setURL(url);
          var resource = this.supermodel.loadModel(levelComponent);
          if (!resource.isLoading) { continue; }
          result.push(this.listenToOnce(resource, 'loaded', function() {
            if (this.handlingChange) { return; }
            this.handlingChange = true;
            this.onComponentsAdded();
            return this.handlingChange = false;
          }));
        }
        return result;
      })();
    }

    afterRender() {
      super.afterRender();
      if (!this.supermodel.finished()) { return; }
      this.buildComponentsTreema();
      this.addThangComponentConfigViews();
      return this.selectKeyComponent();
    }

    buildComponentsTreema() {
      let thangTypeComponents;
      let c;
      const components = _.zipObject(((() => {
        const result = [];
        for (c of Array.from(this.components)) {           result.push(c.original);
        }
        return result;
      })()), this.components);
      let defaultValue = undefined;
      if (thangTypeComponents = this.thangType != null ? this.thangType.get('components', true) : undefined) {
        defaultValue = _.zipObject(((() => {
          const result1 = [];
          for (c of Array.from(thangTypeComponents)) {             result1.push(c.original);
          }
          return result1;
        })()), thangTypeComponents);
      }

      const treemaOptions = {
        supermodel: this.supermodel,
        schema: {
          type: 'object',
          default: defaultValue,
          additionalProperties: Level.schema.properties.thangs.items.properties.components.items
        },
        data: $.extend(true, {}, components),
        callbacks: {select: this.onSelectComponent, change: this.onComponentsTreemaChanged},
        nodeClasses: {
          'object': ThangComponentsObjectNode
        }
      };

      this.componentsTreema = this.$el.find('#thang-components-column .treema').treema(treemaOptions);
      return this.componentsTreema.build();
    }

    onComponentsTreemaChanged() {
      let component;
      if (this.handlingChange) { return; }
      this.handlingChange = true;
      const componentMap = {};
      for (component of Array.from(this.components)) {
        componentMap[component.original] = component;
      }

      const newComponentsList = [];
      for (component of Array.from(_.values(this.componentsTreema.data))) {
        newComponentsList.push(componentMap[component.original] || component);
      }
      this.components = newComponentsList;

      // update the components list here
      this.onComponentsChanged();
      return this.handlingChange = false;
    }

    onComponentsChanged() {
      // happens whenever the list of components changed, one way or another
      // * if the treema gets changed
      // * if components are added externally, like by a modal
      // * if a dependency loads and is added to the list

      if (this.components.length < this.lastComponentLength) {
        this.onComponentsRemoved();
      }
      return this.onComponentsAdded();
    }

    onComponentsRemoved() {
      let component, thangTypeComponents;
      const componentMap = {};
      for (component of Array.from(this.components)) {
        componentMap[component.original] = component;
      }

      const thangComponentMap = {};
      if (thangTypeComponents = this.thangType != null ? this.thangType.get('components') : undefined) {
        for (var thangTypeComponent of Array.from(thangTypeComponents)) {
          thangComponentMap[thangTypeComponent.original] = thangTypeComponent;
        }
      }

      // Deleting components missing dependencies.
      while (true) {
        var removedSomething = false;
        for (var componentRef of Array.from(_.values(componentMap))) {
          var componentModel = this.supermodel.getModelByOriginalAndMajorVersion(
            LevelComponent, componentRef.original, componentRef.majorVersion);
          for (var dependency of Array.from(componentModel.get('dependencies') || [])) {
            if (!componentMap[dependency.original] && !thangComponentMap[dependency.original]) {
              delete componentMap[componentRef.original];
              component = this.supermodel.getModelByOriginal(
                LevelComponent, componentRef.original);
              noty({
                text: `Removed dependent component: ${component.get('name')}`,
                layout: 'topCenter',
                timeout: 5000,
                type: 'information'
              });
              removedSomething = true;
            }
          }
          if (removedSomething) { break; }
        }
        if (!removedSomething) { break; }
      }

      this.components = _.values(componentMap);

      // Delete individual component config views that are no longer included.
      for (var subview of Array.from(_.values(this.subviews))) {
        if (!(subview instanceof ThangComponentConfigView)) { continue; }
        if (!componentMap[subview.component.get('original')] && !thangComponentMap[subview.component.get('original')]) {
          this.removeSubView(subview);
        }
      }

      this.updateComponentsList();
      return this.reportChanges();
    }

    updateComponentsList() {
      // Before I was setting the data to the existing treema but then we had some
      // nasty sorting/callback bugs. This is less efficient, but it's also less bug prone.
      return this.buildComponentsTreema();
    }

    onComponentsAdded() {
      let component, thangTypeComponents;
      if (!this.componentsTreema) { return; }
      const componentMap = {};
      for (component of Array.from(this.components)) {
        componentMap[component.original] = component;
      }

      if (thangTypeComponents = this.thangType != null ? this.thangType.get('components') : undefined) {
        for (var thangTypeComponent of Array.from(thangTypeComponents)) {
          componentMap[thangTypeComponent.original] = thangTypeComponent;
        }
      }

      // Go through the map, adding missing dependencies.
      while (true) {
        var addedSomething = false;
        for (var componentRef of Array.from(_.values(componentMap))) {
          var componentModel = this.supermodel.getModelByOriginalAndMajorVersion(
            LevelComponent, componentRef.original, componentRef.majorVersion);
          if (!(componentModel != null ? componentModel.loaded : undefined)) {
            this.loadComponents([componentRef]);
            continue;
          }
          for (var dependency of Array.from((componentModel != null ? componentModel.get('dependencies') : undefined) || [])) {
            if (!componentMap[dependency.original]) {
              component = this.supermodel.getModelByOriginalAndMajorVersion(
                LevelComponent, dependency.original, dependency.majorVersion);
              if (!(component != null ? component.loaded : undefined)) {
                this.loadComponents([dependency]);
                // will run onComponentsAdded once more when the model loads
              } else {
                addedSomething = true;
                noty({
                  text: `Added dependency: ${component.get('name')}`,
                  layout: 'topCenter',
                  timeout: 5000,
                  type: 'information'
                });
                componentMap[dependency.original] = dependency;
                this.components.push(dependency);
              }
            }
          }
        }
        if (!addedSomething) { break; }
      }


      // Sort the component list, reorder the component config views
      this.updateComponentsList();
      this.addThangComponentConfigViews();
      this.checkForMissingSystems();
      return this.reportChanges();
    }

    addThangComponentConfigViews() {
      // Detach all component config views temporarily.
      let componentRef, subview, thangTypeComponents;
      const componentConfigViews = {};
      for (subview of Array.from(_.values(this.subviews))) {
        if (!(subview instanceof ThangComponentConfigView)) { continue; }
        componentConfigViews[subview.component.get('original')] = subview;
        subview.$el.detach();
      }

      // Put back config views into the DOM based on the component list ordering,
      // adding and registering new ones as needed.
      const configsEl = this.$el.find('#thang-component-configs');

      const componentRefs = _.merge({}, this.componentsTreema.data);
      if (thangTypeComponents = this.thangType != null ? this.thangType.get('components') : undefined) {
        const thangComponentRefs = _.zipObject((Array.from(thangTypeComponents).map((c) => c.original)), thangTypeComponents);
        for (var thangTypeComponent of Array.from(thangTypeComponents)) {
          if (componentRef = componentRefs[thangTypeComponent.original]) {
            componentRef.additionalDefaults = thangTypeComponent.config;
          } else {
            var modifiedRef = _.merge({}, thangTypeComponent);
            modifiedRef.additionalDefaults = modifiedRef.config;
            delete modifiedRef.config;
            componentRefs[thangTypeComponent.original] = modifiedRef;
          }
        }
      }

      return (() => {
        const result = [];
        for (componentRef of Array.from(_.values(componentRefs))) {
          subview = componentConfigViews[componentRef.original];
          if (!subview) {
            subview = this.makeThangComponentConfigView(componentRef);
            if (!subview) { continue; }
            this.registerSubView(subview);
          } else if (!_.isEqual(componentRef.config, subview.config)) {
            subview.setConfig(componentRef.config != null ? componentRef.config : {});
          }
          subview.setIsDefaultComponent(!this.componentsTreema.data[componentRef.original]);
          result.push(configsEl.append(subview.$el));
        }
        return result;
      })();
    }

    makeThangComponentConfigView(thangComponent) {
      const component = this.supermodel.getModelByOriginal(LevelComponent, thangComponent.original);
      if (!(component != null ? component.loaded : undefined)) { return; }
      const config = thangComponent.config != null ? thangComponent.config : {};
      const configView = new ThangComponentConfigView({
        supermodel: this.supermodel,
        level: this.level,
        world: this.world,
        config,
        component,
        additionalDefaults: thangComponent.additionalDefaults
      });
      configView.render();
      this.listenTo(configView, 'changed', this.onConfigChanged);
      return configView;
    }

    onConfigChanged(e) {
      let foundComponent = false;
      for (var thangComponent of Array.from(this.components)) {
        if (thangComponent.original === e.component.get('original')) {
          thangComponent.config = e.config;
          foundComponent = true;
          break;
        }
      }

      if (!foundComponent) {
        this.components.push({
          original: e.component.get('original'),
          majorVersion: e.component.get('version').major,
          config: e.config
        });

        for (var subview of Array.from(_.values(this.subviews))) {
          if (!(subview instanceof ThangComponentConfigView)) { continue; }
          if (subview.component.get('original') === e.component.get('original')) {
            _.defer(() => subview.setIsDefaultComponent(false));
            break;
          }
        }
      }

      this.updateComponentsList();
      return this.reportChanges();
    }

    selectKeyComponent() {
      return (() => {
        const result = [];
        for (var child of Array.from(_.values(this.componentsTreema.childrenTreemas))) {
          var needle;
          if ((needle = child.keyForParent, Array.from([LevelComponent.RefereeID].concat(LevelComponent.ProgrammableIDs)).includes(needle))) {
            this.onSelectComponent(null, [child]);
            break;
          } else {
            result.push(undefined);
          }
        }
        return result;
      })();
    }

    onSelectComponent(e, nodes) {
      this.componentsTreema.$el.find('.dependent').removeClass('dependent');
      this.$el.find('.selected-component').removeClass('selected-component');
      if (nodes.length !== 1) { return; }

      // find dependent components
      const dependents = {};
      dependents[nodes[0].getData().original] = true;
      const componentsToCheck = [nodes[0].getData().original];
      while (componentsToCheck.length) {
        var componentOriginal = componentsToCheck.pop();
        for (var otherComponentRef of Array.from(this.components)) {
          if (otherComponentRef.original === componentOriginal) { continue; }
          if (dependents[otherComponentRef.original]) { continue; }
          var otherComponent = this.supermodel.getModelByOriginal(LevelComponent, otherComponentRef.original);
          for (var dependency of Array.from(otherComponent.get('dependencies', true))) {
            if (dependents[dependency.original]) {
              dependents[otherComponentRef.original] = true;
              componentsToCheck.push(otherComponentRef.original);
            }
          }
        }
      }

      // highlight them
      for (var child of Array.from(_.values(this.componentsTreema.childrenTreemas))) {
        if (dependents[child.getData().original]) {
          child.$el.addClass('dependent');
        }
      }

      // scroll to the config
      return (() => {
        const result = [];
        for (var subview of Array.from(_.values(this.subviews))) {
          if (!(subview instanceof ThangComponentConfigView)) { continue; }
          if (subview.component.get('original') === nodes[0].getData().original) {
            subview.$el[0].scrollIntoView();
            subview.$el.addClass('selected-component');
            break;
          } else {
            result.push(undefined);
          }
        }
        return result;
      })();
    }

    onChangeExtantComponents() {
      this.buildAddComponentTreema();
      return this.reportChanges();
    }

    checkForMissingSystems() {
      let c;
      if (!this.level) { return; }
      if (utils.isOzaria) { return; }  // Ozaria has different systems and doesn't track relationships between Components and Systems there
      const extantSystems =
        (() => {
        const result = [];
        const object = this.level.get('systems');
        for (var idx in object) {
          var sn = object[idx];
          result.push((this.supermodel.getModelByOriginalAndMajorVersion(LevelSystem, sn.original, sn.majorVersion)).attributes.name.toLowerCase());
        }
        return result;
      })();

      const componentModels = ((() => {
        const result1 = [];
        for (c of Array.from(this.components)) {           result1.push(this.supermodel.getModelByOriginal(LevelComponent, c.original));
        }
        return result1;
      })());
      const componentSystems = ((() => {
        const result2 = [];
        for (c of Array.from(componentModels)) {           if (c) {
            result2.push(c.get('system'));
          }
        }
        return result2;
      })());

      return (() => {
        const result3 = [];
        for (var system of Array.from(componentSystems)) {
          if ((system !== 'misc') && !Array.from(extantSystems).includes(system)) {
            var s = `Component requires system <strong>${system}</strong> which is currently not included in this level.`;
            result3.push(noty({
              text: s,
              layout: 'bottomLeft',
              type: 'warning'
            }));
          } else {
            result3.push(undefined);
          }
        }
        return result3;
      })();
    }

    reportChanges() {
      this.lastComponentLength = this.components.length;
      return this.trigger('components-changed', $.extend(true, [], this.components));
    }

    undo() { return this.componentsTreema.undo(); }

    redo() { return this.componentsTreema.redo(); }

    onAddComponentsButtonClicked() {
      let c;
      const modal = new AddThangComponentsModal({skipOriginals: ((() => {
        const result = [];
        for (c of Array.from(this.components)) {           result.push(c.original);
        }
        return result;
      })())});
      this.openModalView(modal);
      return this.listenToOnce(modal, 'hidden', function() {
        const componentsToAdd = modal.getSelectedComponents();
        const sparseComponents = ((() => {
          const result1 = [];
          for (c of Array.from(componentsToAdd)) {             result1.push({original: c.get('original'), majorVersion: c.get('version').major});
          }
          return result1;
        })());
        this.loadComponents(sparseComponents);
        this.components = this.components.concat(sparseComponents);
        return this.onComponentsChanged();
      });
    }

    onThangTypeKindChanged(e) {
      let defaultComponents;
      if (!(defaultComponents = DEFAULT_COMPONENTS[e.kind])) { return; }
      return (() => {
        const result = [];
        for (var component of Array.from(defaultComponents)) {
          if (!_.find(this.components, {original: component.original})) {
            this.components.push(component);
            result.push(this.onComponentsAdded());
          }
        }
        return result;
      })();
    }

    destroy() {
      if (this.componentsTreema != null) {
        this.componentsTreema.destroy();
      }
      return super.destroy();
    }
  };
  ThangComponentsEditView.initClass();
  return ThangComponentsEditView;
})());

class ThangComponentsObjectNode extends TreemaObjectNode {
  constructor(...args) {
    super(...args);
    this.sortFunction = this.sortFunction.bind(this);
  }

  addNewChild() { return this.addNewChildForKey(''); } // HACK to get the object adding to act more like adding to an array

  getChildren() {
    const children = super.getChildren(...arguments);
    return children.sort(this.sortFunction);
  }

  sortFunction(a, b) {
    a = a.value != null ? a.value : a.defaultData;
    b = b.value != null ? b.value : b.defaultData;
    a = this.settings.supermodel.getModelByOriginalAndMajorVersion(LevelComponent, a.original, a.majorVersion);
    b = this.settings.supermodel.getModelByOriginalAndMajorVersion(LevelComponent, b.original, b.majorVersion);
    if (!(a || b)) { return 0; }
    if (!b) { return 1; }
    if (!a) { return -1; }
    if (a.get('system') > b.get('system')) { return 1; }
    if (a.get('system') < b.get('system')) { return -1; }
    if (a.get('name') > b.get('name')) { return 1; }
    if (a.get('name') < b.get('name')) { return -1; }
    return 0;
  }
}
