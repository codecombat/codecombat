// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ModalComponent;
const ModalView = require('./ModalView');
const store = require('core/store');
const silentStore = { commit: _.noop, dispatch: _.noop };

module.exports = (ModalComponent = (function() {
  ModalComponent = class ModalComponent extends ModalView {
    static initClass() {
      this.prototype.VueComponent = null; // set this - will overwrite backbone modal
      this.prototype.vuexModule = null;
      this.prototype.propsData = null;
    }

    afterRender() {
      if (this.vueComponent) {
        return this.$el.find('#modal-base-flat').replaceWith(this.vueComponent.$el);
        // TODO: should we call super() here?
      } else {
        if (this.vuexModule) {
          if (!_.isFunction(this.vuexModule)) {
            throw new Error('@vuexModule should be a function');
          }
          store.registerModule('modal', this.vuexModule());
        }

        this.vueComponent = new this.VueComponent({
          el: this.$el.find('#modal-base-flat')[0],
          propsData: this.propsData,
          store
        });

        return super.afterRender(...arguments);
      }
    }

    destroy() {
      if (this.vuexModule) {
        store.unregisterModule('modal');
      }
      // Reference for how to safely destroy a vue component:
      // https://forum.vuejs.org/t/add-component-to-dom-programatically/7308/12
      this.vueComponent.$destroy();
      this.vueComponent.$el.remove();
      this.vueComponent.$store = silentStore;
      this.vueComponent = null;
      return super.destroy();
    }
  };
  ModalComponent.initClass();
  return ModalComponent;
})());
