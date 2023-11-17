/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ModelModal;
require('app/styles/modal/model-modal.sass');
const ModalView = require('views/core/ModalView');
const template = require('app/templates/modal/model-modal');
require('lib/setupTreema');

module.exports = (ModelModal = (function() {
  ModelModal = class ModelModal extends ModalView {
    static initClass() {
      this.prototype.id = 'model-modal';
      this.prototype.template = template;
      this.prototype.plain = true;

      this.prototype.events = {'click .save-model': 'onSaveModel'};
    }

    constructor (options = {}) {
      super(options)
      this.models = !options.models ? options.models : [];
      const result = []
      for (const model of Array.from(this.models)) {
        if (!model.loaded) {
          this.supermodel.loadModel(model);
          result.push(model.fetch({cache: false, error(error) {
            return console.log('Error loading', model, error);
          }
          }));
        }
      }
    }

    afterRender() {
      if (!this.supermodel.finished()) { return; }
      this.modelTreemas = {};
      return (() => {
        const result = [];
        for (var model of Array.from(this.models != null ? this.models : [])) {
          var data = $.extend(true, {}, model.attributes);
          var schema = $.extend(true, {}, model.schema());
          var treemaOptions = {
            schema,
            data,
            readOnly: false
          };
          var modelTreema = this.$el.find(`.model-treema[data-model-id='${model.id}']`).treema(treemaOptions);
          if (modelTreema != null) {
            modelTreema.build();
          }
          if (modelTreema != null) {
            modelTreema.open();
          }
          this.openTastyTreemas(modelTreema, model);
          result.push(this.modelTreemas[model.id] = modelTreema);
        }
        return result;
      })();
    }

    openTastyTreemas(modelTreema, model) {
      // To save on quick inspection, let's auto-open the properties we're most likely to want to see.
      const delicacies = ['code', 'properties'];
      return (() => {
        const result = [];
        for (var dish of Array.from(delicacies)) {
          var team;
          var child = modelTreema.childrenTreemas[dish];
          if (child != null) {
            child.open();
          }
          if (child && (dish === 'code') && (model.type() === 'LevelSession') && (team = modelTreema.get('team'))) {
            var desserts = {
              humans: ['hero-placeholder'],
              ogres: ['hero-placeholder-1']
            }[team];
            result.push(Array.from(desserts).map((dessert) =>
              (child.childrenTreemas[dessert] != null ? child.childrenTreemas[dessert].open() : undefined)));
          } else {
            result.push(undefined);
          }
        }
        return result;
      })();
    }

    onSaveModel(e) {
      let errors, key, res, val;
      const container = $(e.target).closest('.model-container');
      const model = _.find(this.models, {id: container.data('model-id')});
      const treema = this.modelTreemas[model.id];
      for (key in treema.data) {
        val = treema.data[key];
        if (!_.isEqual(val, model.get(key))) {
          console.log('Updating', key, 'from', model.get(key), 'to', val);
          model.set(key, val);
        }
      }
      for (key in model.attributes) {
        val = model.attributes[key];
        if ((treema.get(key) === undefined) && !_.string.startsWith(key, '_')) {
          console.log('Deleting', key, 'which was', val, 'but man, that ain\'t going to work, now is it?');
        }
      }
        //model.unset key
      if (errors = model.validate()) {
        return console.warn(model, 'failed validation with errors:', errors);
      }
      if (!(res = model.patch())) { return; }
      res.error(() => {
        if (this.destroyed) { return; }
        return console.error(model, 'failed to save with error:', res.responseText);
      });
      return res.success((model, response, options) => {
        if (this.destroyed) { return; }
        return this.hide();
      });
    }

    destroy() {
      for (var model in this.modelTreemas) { this.modelTreemas[model].destroy(); }
      return super.destroy();
    }
  };
  ModelModal.initClass();
  return ModelModal;
})());
