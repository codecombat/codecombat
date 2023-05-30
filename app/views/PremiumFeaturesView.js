// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let PremiumFeaturesView;
import 'app/styles/premium-features-view.sass';
import RootView from 'views/core/RootView';
import SubscribeModal from 'views/core/SubscribeModal';
import template from 'templates/premium-features-view';
import utils from 'core/utils';
import storage from 'core/storage';
import paymentUtils from 'app/lib/paymentUtils';

export default PremiumFeaturesView = (function() {
  PremiumFeaturesView = class PremiumFeaturesView extends RootView {
    static initClass() {
      this.prototype.id = 'premium-features-view';
      this.prototype.template = template;
  
      this.prototype.i18nData = utils.premiumContent;
  
      this.prototype.events =
        {'click .buy': 'onClickBuy'};
  
      this.prototype.subscriptions =
        {'subscribe-modal:subscribed': 'onSubscribed'};
    }

    constructor(options) {
      if (options == null) { options = {}; }
      super(options);
      this.hasTemporaryPremiumAccess = paymentUtils.hasTemporaryPremiumAccess();
    }

    afterInsert() {
      // Automatically open sub modal, unless it will open later via storage sub-modal-continue flag
      if ((utils.getQueryVariable('pop') != null) && !storage.load('sub-modal-continue')) {
        this.openSubscriptionModal();
      }
      // This super() must follow open sub check above to avoid double sub modal via CocoView.afterInsert()
      return super.afterInsert();
    }

    openSubscriptionModal() {
      return this.openModalView(new SubscribeModal());
    }

    onClickBuy(e) {
      this.openSubscriptionModal();
      const buttonLocation = $(e.currentTarget).data('button-location');
      return (window.tracker != null ? window.tracker.trackEvent('Show subscription modal', {category: 'Subscription', label: `get premium view ${buttonLocation}`}) : undefined);
    }

    onSubscribed() {
      return this.render();
    }
  };
  PremiumFeaturesView.initClass();
  return PremiumFeaturesView;
})();
