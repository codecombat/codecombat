// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const loadPayPal = _.once(() => new Promise((accept, reject) => $.getScript('https://www.paypalobjects.com/api/checkout.js', () => accept())))

// https://developer.paypal.com/docs/integration/direct/express-checkout/integration-jsv4/customize-button/#supported-locales
const acceptableLanguages = [
  'en_US', 'en_AU', 'en_GB', 'fr_CA', 'es_ES', 'it_IT', 'fr_FR', 'de_DE', 'pt_BR', 'zh_CN', 'da_DK', 'zh_HK', 'id_ID', 'he_IL', 'ja_JP', 'nl_NL', 'no_NO', 'pl_PL', 'pt_PT', 'ru_RU', 'sv_SE', 'th_TH', 'zh_TW'
]

const makeButton = function (options) {
  const { buttonContainerID, product, onPaymentStarted, onPaymentComplete, description } = options
  return typeof paypal !== 'undefined' && paypal !== null ? paypal.Button.render(_.assign({
    env: application.isProduction() ? 'production' : 'sandbox', // sandbox | production

    locale: (() => {
      const preferredLanguage = (me.get('preferredLanguage') || 'en-US').replace('-', '_')
      if (Array.from(acceptableLanguages).includes(preferredLanguage)) { return preferredLanguage } else { return 'en_US' }
    }
    )(),
    // Style the button: https://developer.paypal.com/docs/integration/direct/express-checkout/integration-jsv4/customize-button/
    style: {
      size: 'responsive',
      shape: 'rect'
    },

    // PayPal Client IDs - replace with your own
    // Create a PayPal app: https://developer.paypal.com/developer/applications/create
    client: {
      sandbox: 'AcS4lYmr_NwK_TTWSJzOzTh01tVDceWDjB_N7df3vlvW4alTV_AF2rtmcaZDh0AmnTcOof9gKyLyHkm-',
      production: 'AXP_Bf0KAz8_HV0X6EFSu9cMAXcb7AoaRAYqrfPKBxnl5zTWEt5JzMTMJdXiCjK29AFlp_zAdP4zefRD'
    },
    // Show the buyer a 'Pay Now' button in the checkout flow
    commit: true,
    // payment() is called when the button is clicked
    payment (data, actions) {
      // Make a call to the REST api to create the payment
      onPaymentStarted()
      const paymentData = {
        payment: {
          transactions: [
            {
              amount: { total: product.adjustedPriceStringNoSymbol(), currency: 'USD' },
              item_list: {
                items: [{
                  sku: product.id,
                  name: product.translateName(),
                  quantity: 1,
                  price: product.adjustedPriceStringNoSymbol(),
                  currency: 'USD'
                }]
              },
              description // Is this what shows up on their credit card, or so? TODO: Translate?
            }
          ]
        }
      }
      return actions.payment.create(paymentData)
    },
    // onAuthorize() is called when the buyer approves the payment
    onAuthorize (data, actions) {
      // Pass the payment info along, so we can tell the server to execute it
      return actions.payment.get().then(payment => onPaymentComplete(payment))
    }
  }, options.payPalOptions), buttonContainerID) : undefined
}

module.exports = {
  loadPayPal,
  makeButton
}
