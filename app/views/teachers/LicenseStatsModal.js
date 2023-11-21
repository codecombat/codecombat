/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS102: Remove unnecessary code created because of implicit returns
 * DS104: Avoid inline assignments
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let LicenseStatsModal;
const ModalComponent = require('views/core/ModalComponent');
const LicenseStatsComponent = require('./components/LicenseStatsModal.vue').default;

module.exports = (LicenseStatsModal = (function() {
  LicenseStatsModal = class LicenseStatsModal extends ModalComponent {
    static initClass() {
      this.prototype.id = 'license-stats-modal';
      this.prototype.template = require('app/templates/core/modal-base-flat');
      this.prototype.VueComponent = LicenseStatsComponent;
    }

    constructor(options) {
      super(options);
      let left, left1;
      this.nameMapping = this.nameMapping.bind(this);
      this.prepaid = options.prepaid;

      this.redeemers = (left = this.prepaid.get('redeemers')) != null ? left : [];
      const redeemerIds = this.redeemers.map(r => {
        return r.userID;
      });
      this.removedRedeemers = (left1 = this.prepaid.get('removedRedeemers')) != null ? left1 : [];
      const removedRedeemerIds = this.removedRedeemers.map(r => {
        return r.userID;
      });
      this.propsData = {
        hide: () => this.hide(),
        loading: { finished: false },
        prepaid: this.prepaid,
        redeemers: this.redeemers,
        removedRedeemers: this.removedRedeemers
      };

      this.supermodel.resetProgress();
      const userNameRequest = this.supermodel.addRequestResource('user_names', {
        url: '/db/user/-/names',
        data: {ids: redeemerIds.concat(removedRedeemerIds)},
        method: 'POST',
        success: nameMap => {
          this.nameMap = nameMap;
          this.redeemers.forEach(this.nameMapping);
          this.removedRedeemers.forEach(this.nameMapping);
          return this.propsData.loading.finished = true;
        }
      });
      userNameRequest.load();
    }

    nameMapping(r, index, arr) {
      let name;
      const user = this.nameMap[r.userID];
      if (user != null ? user.firstName : undefined) { name = user.firstName; }
      if ((user != null ? user.lastName : undefined) != null) { name += ' ' + user.lastName; }
      if (!name) { name = user != null ? user.name : undefined; }
      return arr[index].name = name;
    }

    destroy() {
      if (typeof this.onDestroy === 'function') {
        this.onDestroy();
      }
      return super.destroy();
    }
  };
  LicenseStatsModal.initClass();
  return LicenseStatsModal;
})());
