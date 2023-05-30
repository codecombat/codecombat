/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let NewItemView;
import 'app/styles/play/level/modal/new-item-view.sass';
import CocoView from 'views/core/CocoView';

export default NewItemView = (function() {
  NewItemView = class NewItemView extends CocoView {
    static initClass() {
      this.prototype.id = 'new-item-view';
      this.prototype.className = 'modal-content';
      this.prototype.template = require('app/templates/play/level/modal/new-item-view');
  
      this.prototype.events =
        {'click #continue-btn': 'onClickContinueButton'};
    }

    afterRender() {
      return super.afterRender();
    }
      // TODO: Animate icon

    initialize(options) {
      this.item = options.item;
      return super.initialize();
    }

    onClickContinueButton() {
      return this.trigger('continue');
    }
  };
  NewItemView.initClass();
  return NewItemView;
})();
