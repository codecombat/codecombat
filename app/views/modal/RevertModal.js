/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let RevertModal;
import 'app/styles/modal/revert-modal.sass';
import ModalView from 'views/core/ModalView';
import template from 'app/templates/modal/revert-modal';
import CocoModel from 'models/CocoModel';

export default RevertModal = (function() {
  RevertModal = class RevertModal extends ModalView {
    static initClass() {
      this.prototype.id = 'revert-modal';
      this.prototype.template = template;
  
      this.prototype.events =
        {'click #changed-models button': 'onRevertModel'};
    }

    onRevertModel(e) {
      const id = $(e.target).val();
      CocoModel.backedUp[id].revert();
      $(e.target).closest('tr').remove();
      return this.reloadOnClose = true;
    }

    getRenderData() {
      const c = super.getRenderData();
      let models = _.values(CocoModel.backedUp);
      models = ((() => {
        const result = [];
        for (var m of Array.from(models)) {           if (m.hasLocalChanges()) {
            result.push(m);
          }
        }
        return result;
      })());
      c.models = models;
      return c;
    }

    onHidden() {
      if (this.reloadOnClose) { return location.reload(); }
    }
  };
  RevertModal.initClass();
  return RevertModal;
})();
