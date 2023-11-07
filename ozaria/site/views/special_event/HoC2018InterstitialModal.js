/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let HoC2018InterstitialModal;
const ModalComponent = require('views/core/ModalComponent');
const HoCInterstitialComponent = require('./HoC2018InterstitialModal.vue').default;

module.exports = (HoC2018InterstitialModal = (function() {
  HoC2018InterstitialModal = class HoC2018InterstitialModal extends ModalComponent {
    static initClass() {
      this.prototype.id = 'hoc-interstitial-modal';
      this.prototype.template = require('templates/core/modal-base-flat');
      this.prototype.closeButton = true;
      this.prototype.VueComponent = HoCInterstitialComponent;
    }

    // Runs before the constructor is called.
    initialize() {
      this.propsData = {
        clickStudent: () => this.hide(),
        clickTeacher: () => application.router.navigate('/teachers/hour-of-code', { trigger: true }),
        showVideo: false
      };
    }
    constructor(options) {
      super(options);
      this.propsData.showVideo = (options != null ? options.showVideo : undefined) || false;
      this.onDestroy = options != null ? options.onDestroy : undefined;
    }

    destroy() {
      if (typeof this.onDestroy === 'function') {
        this.onDestroy();
      }
      return super.destroy();
    }
  };
  HoC2018InterstitialModal.initClass();
  return HoC2018InterstitialModal;
})());
