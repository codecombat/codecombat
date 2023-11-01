/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS104: Avoid inline assignments
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let AddLevelSystemModal;
require('app/styles/editor/level/system/add.sass');
const ModalView = require('views/core/ModalView');
const template = require('app/templates/editor/level/system/add');
const availableSystemTemplate = require('app/templates/editor/level/system/available_system');
const LevelSystem = require('models/LevelSystem');
const CocoCollection = require('collections/CocoCollection');

class LevelSystemSearchCollection extends CocoCollection {
  static initClass() {
    this.prototype.url = '/db/level.system';
    this.prototype.model = LevelSystem;
  }
}
LevelSystemSearchCollection.initClass();

module.exports = (AddLevelSystemModal = (function() {
  AddLevelSystemModal = class AddLevelSystemModal extends ModalView {
    static initClass() {
      this.prototype.id = 'editor-level-system-add-modal';
      this.prototype.template = template;
      this.prototype.instant = true;
  
      this.prototype.events =
        {'click .available-systems-list li': 'onAddSystem'};
    }

    constructor(options) {
      super(options);
      this.extantSystems = options.extantSystems != null ? options.extantSystems : [];
      this.systems = this.supermodel.loadCollection(new LevelSystemSearchCollection(), 'systems').model;
    }

    afterRender() {
      super.afterRender();
      if (!this.supermodel.finished()) { return; }
      return this.renderAvailableSystems();
    }

    renderAvailableSystems() {
      const ul = this.$el.find('ul.available-systems-list').empty();
      let systems = (Array.from(this.systems.models).map((m) => m.attributes));
      _.remove(systems, system => {
        return _.find(this.extantSystems, {original: system.original});
    });  // already have this one added
      systems = _.sortBy(systems, 'name');
      return (() => {
        const result = [];
        for (var system of Array.from(systems)) {
          result.push(ul.append($(availableSystemTemplate({system}))));
        }
        return result;
      })();
    }

    onAddSystem(e) {
      const id = $(e.currentTarget).data('system-id');
      const system = _.find(this.systems.models, {id});
      if (!system) {
        return console.error('Couldn\'t find system for id', id, 'out of', this.systems.models);
      }
      // Add all dependencies, recursively, unless we already have them
      const toAdd = system.getDependencies(this.systems.models);
      _.remove(toAdd, s1 => {
        return _.find(this.extantSystems, {original: s1.get('original')});
      });
      for (var s of Array.from(toAdd.concat([system]))) {
        var left, left1;
        var levelSystem = {
          original: (left = s.get('original')) != null ? left : id,
          majorVersion: (left1 = s.get('version').major) != null ? left1 : 0
        };
        this.extantSystems.push(levelSystem);
        Backbone.Mediator.publish('editor:level-system-added', {system: levelSystem});
      }
      return this.renderAvailableSystems();
    }
  };
  AddLevelSystemModal.initClass();
  return AddLevelSystemModal;
})());
