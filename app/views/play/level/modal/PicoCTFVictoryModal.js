/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let PicoCTFVictoryModal;
require('app/styles/play/level/modal/course-victory-modal.sass');
const ModalView = require('views/core/ModalView');
const template = require('app/templates/play/level/modal/picoctf-victory-modal');
const Level = require('models/Level');

module.exports = (PicoCTFVictoryModal = (function() {
  PicoCTFVictoryModal = class PicoCTFVictoryModal extends ModalView {
    static initClass() {
      this.prototype.id = 'picoctf-victory-modal';
      this.prototype.template = template;
      this.prototype.closesOnClickOutside = false;
    }

    initialize(options) {
      let nextLevel;
      this.session = options.session;
      this.level = options.level;

      const form = {flag: options.world.picoCTFFlag, pid: this.level.picoCTFProblem.pid};
      this.supermodel.addRequestResource({url: '/picoctf/submit', method: 'POST', data: form, success: response => {
        return console.log('submitted', form, 'and got response', response);
      }
      }).load();

      if (nextLevel = this.level.get('nextLevel')) {
        this.nextLevel = new Level().setURL(`/db/level/${nextLevel.original}/version/${nextLevel.majorVersion}`);
        this.nextLevel = this.supermodel.loadModel(this.nextLevel).model;
      }

      return this.playSound('victory');
    }

    onLoaded() {
      return super.onLoaded();
    }
  };
  PicoCTFVictoryModal.initClass();
  return PicoCTFVictoryModal;
})());
