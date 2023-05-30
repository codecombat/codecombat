/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS104: Avoid inline assignments
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let BuyGemsModal;
import 'app/styles/play/modal/buy-gems-modal.sass';
import 'app/styles/play/modal/lang-nl/buy-gems-modal-nl.sass';
import ModalView from 'views/core/ModalView';
import template from 'app/templates/play/modal/buy-gems-modal';
import stripeHandler from 'core/services/stripe';
import utils from 'core/utils';
import SubscribeModal from 'views/core/SubscribeModal';
import Products from 'collections/Products';
import CreateAccountModal from 'views/core/CreateAccountModal';

export default BuyGemsModal = (function() {
  BuyGemsModal = class BuyGemsModal extends ModalView {
    static initClass() {
      this.prototype.id =
        (me.get('preferredLanguage',true) || 'en-US').split('-')[0] === 'nl' ?
          'buy-gems-modal-nl'
        :
          'buy-gems-modal';
      this.prototype.template = template;
      this.prototype.plain = true;
  
      this.prototype.subscriptions = {
        'ipad:products': 'onIPadProducts',
        'ipad:iap-complete': 'onIAPComplete',
        'stripe:received-token': 'onStripeReceivedToken'
      };
  
      this.prototype.events = {
        'click .product button:not(.start-subscription-button)': 'onClickProductButton',
        'click #close-modal': 'hide',
        'click .start-subscription-button': 'onClickStartSubscription'
      };
    }

    constructor(options) {
      super(options);
      this.timestampForPurchase = new Date().getTime();
      this.state = 'standby';
      this.products = new Products();
      this.products.comparator = 'amount';
      if (application.isIPadApp) {
        this.products = [];
        Backbone.Mediator.publish('buy-gems-modal:update-products');
      } else {
        this.supermodel.loadCollection(this.products, 'products');
        $.post('/db/payment/check-stripe-charges', (something, somethingElse, jqxhr) => {
          if (jqxhr.status === 201) {
            this.state = 'recovered_charge';
            return this.render();
          }
        });
      }
      this.trackTimeVisible({ trackViewLifecycle: true });
    }

    onLoaded() {
      this.basicProduct = this.products.getBasicSubscriptionForUser(me);
      this.lifetimeProduct = this.products.getLifetimeSubscriptionForUser(me);
      this.products.reset(this.products.filter(product => _.string.startsWith(product.get('name'), 'gems_')));
      return super.onLoaded();
    }

    afterRender() {
      super.afterRender();
      if (!this.supermodel.finished()) { return; }
      this.playSound('game-menu-open');
      if (this.basicProduct) {
        return this.$el.find('.subscription-gem-amount').text($.i18n.t('buy_gems.price').replace('{{gems}}', this.basicProduct.get('gems')));
      }
    }

    onHidden() {
      super.onHidden();
      return this.playSound('game-menu-close');
    }

    onIPadProducts(e) {}
      // TODO: Update to handle new products collection
  //    newProducts = []
  //    for iapProduct in e.products
  //      localProduct = _.find @originalProducts, { id: iapProduct.id }
  //      continue unless localProduct
  //      localProduct.price = iapProduct.price
  //      newProducts.push localProduct
  //    @products = _.sortBy newProducts, 'gems'
  //    @render()

    getProductDescription(productName) {
      switch (productName) {
        case 'gems_5': return 'buy_gems.few_gems';
        case 'gems_10': return 'buy_gems.pile_gems';
        case 'gems_20': return 'buy_gems.chest_gems';
        default: return '';
      }
    }

    onClickProductButton(e) {
      this.playSound('menu-button-click');
      if (me.get('anonymous')) { return this.openModalView(new CreateAccountModal()); }
      const productID = $(e.target).closest('button').val();
      // Don't throw error when product is not found
      if (productID.length === 0) {
        return;
      }
      const product = this.products.findWhere({ name: productID });

      if (application.isIPadApp) {
        Backbone.Mediator.publish('buy-gems-modal:purchase-initiated', { productID });

      } else {
        if (application.tracker != null) {
          application.tracker.trackEvent('Started gem purchase', { productID });
        }
        stripeHandler.open({
          description: $.t(this.getProductDescription(product.get('name'))),
          amount: product.get('amount'),
          bitcoin: true,
          alipay: (me.get('country') === 'china') || ((me.get('preferredLanguage') || 'en-US').slice(0, 2) === 'zh') ? true : 'auto'
        });
      }

      return this.productBeingPurchased = product;
    }

    onStripeReceivedToken(e) {
      const data = {
        productID: this.productBeingPurchased.get('name'),
        stripe: {
          token: e.token.id,
          timestamp: this.timestampForPurchase
        }
      };
      this.state = 'purchasing';
      this.render();
      const jqxhr = $.post('/db/payment', data);
      jqxhr.done(() => {
        if (application.tracker != null) {
          application.tracker.trackEvent('Finished gem purchase', {
          productID: this.productBeingPurchased.get('name'),
          value: this.productBeingPurchased.get('amount')
        }
        );
        }
        return document.location.reload();
      });
      return jqxhr.fail(function() {
        if (jqxhr.status === 402) {
          this.state = 'declined';
          this.stateMessage = arguments[2];
        } else if (jqxhr.status === 500) {
          this.state = 'retrying';
          const f = _.bind(this.onStripeReceivedToken, this, e);
          _.delay(f, 2000);
        } else {
          this.state = 'unknown_error';
          this.stateMessage = `${jqxhr.status}: ${jqxhr.responseText}`;
        }
        return this.render();
      }.bind(this));
    }

    onIAPComplete(e) {
      let left;
      const product = this.products.findWhere({ name: e.productID });
      let purchased = (left = me.get('purchased')) != null ? left : {};
      purchased = _.clone(purchased);
      if (purchased.gems == null) { purchased.gems = 0; }
      purchased.gems += product.gems;
      me.set('purchased', purchased);
      return this.hide();
    }

    onClickStartSubscription(e) {
      this.openModalView(new SubscribeModal());
      return (window.tracker != null ? window.tracker.trackEvent('Show subscription modal', {category: 'Subscription', label: 'buy gems modal'}) : undefined);
    }
  };
  BuyGemsModal.initClass();
  return BuyGemsModal;
})();
