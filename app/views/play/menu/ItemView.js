/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ItemView;
import CocoView from 'views/core/CocoView';
import template from 'app/templates/play/menu/item-view';

export default ItemView = (function() {
  ItemView = class ItemView extends CocoView {
    static initClass() {
      this.prototype.className = 'item-view';
  
      this.prototype.template = template;
    }

    initialize(options) {
      super.initialize(...arguments);
      this.item = options.item;
      return this.includes = options.includes || {};
    }

    getRenderData() {
      const c = super.getRenderData();
      c.item = this.item;
      c.includes = this.includes;
      if (this.includes.props || this.includes.stats) {
        const {props, stats} = this.item.getFrontFacingStats();
        c.props = props;
        c.stats = stats;
      }
      return c;
    }

    afterRender() {
      return this.$el.data('item-id', this.item.id);
    }
  };
  ItemView.initClass();
  return ItemView;
})();
