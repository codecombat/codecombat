// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let RootComponent;
const RootView = require('./RootView');
const store = require('core/store');
const silentStore = { commit: _.noop, dispatch: _.noop };

module.exports = (RootComponent = (function() {
  RootComponent = class RootComponent extends RootView {
    static initClass() {
      this.prototype.VueComponent = null; // set this
      this.prototype.vuexModule = null;
      this.prototype.propsData = null;
    }

    afterRender() {
      if (this.vueComponent) {
        this.$el.find('#site-content-area').replaceWith(this.vueComponent.$el);
      } else {
        if (this.vuexModule) {
          if (!_.isFunction(this.vuexModule)) {
            throw new Error('@vuexModule should be a function');
          }
          store.registerModule('page', this.vuexModule());
        }

        this.vueComponent = new this.VueComponent({
          el: this.$el.find('#site-content-area')[0],
          propsData: this.propsData,
          store
        });

        window.rootComponent = this.vueComponent; // Don't use this in code! Just for ease of development
      }

      return super.afterRender(...arguments);
    }

    destroy() {
      if (this.vuexModule) {
        store.unregisterModule('page');
      }
      this.vueComponent.$destroy();
      this.vueComponent.$store = silentStore;
      // ignore all further changes to the store, since the module has been unregistered.
      // may later want to just ignore mutations and actions to the page module.
      return super.destroy();
    }
  };
  RootComponent.initClass();
  return RootComponent;
})());
