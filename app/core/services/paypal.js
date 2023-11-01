loadPayPal = _.once () ->
  return new Promise (accept, reject) ->
    $.getScript 'https://www.paypalobjects.com/api/checkout.js', ->
      accept()
      
# https://developer.paypal.com/docs/integration/direct/express-checkout/integration-jsv4/customize-button/#supported-locales
acceptableLanguages = [
  "en_US", "en_AU", "en_GB", "fr_CA", "es_ES", "it_IT", "fr_FR", "de_DE", "pt_BR", "zh_CN", "da_DK", "zh_HK", "id_ID", "he_IL", "ja_JP", "nl_NL", "no_NO", "pl_PL", "pt_PT", "ru_RU", "sv_SE", "th_TH", "zh_TW"
]

makeButton = (options) ->
  { buttonContainerID, product, onPaymentStarted, onPaymentComplete, description } = options
  paypal?.Button.render(_.assign({
    env: if application.isProduction() then 'production' else 'sandbox', # sandbox | production
    
    locale: (=>
      preferredLanguage = (me.get('preferredLanguage') or 'en-US').replace('-', '_')
      if preferredLanguage in acceptableLanguages then preferredLanguage else 'en_US'
    )()
    # Style the button: https://developer.paypal.com/docs/integration/direct/express-checkout/integration-jsv4/customize-button/
    style: {
      size: 'responsive'
      shape: 'rect'
    }

    # PayPal Client IDs - replace with your own
    # Create a PayPal app: https://developer.paypal.com/developer/applications/create
    client: {
      sandbox:    'AcS4lYmr_NwK_TTWSJzOzTh01tVDceWDjB_N7df3vlvW4alTV_AF2rtmcaZDh0AmnTcOof9gKyLyHkm-'
      production: 'AXP_Bf0KAz8_HV0X6EFSu9cMAXcb7AoaRAYqrfPKBxnl5zTWEt5JzMTMJdXiCjK29AFlp_zAdP4zefRD'
    },
    # Show the buyer a 'Pay Now' button in the checkout flow
    commit: true,
    # payment() is called when the button is clicked
    payment: (data, actions) ->
      # Make a call to the REST api to create the payment
      onPaymentStarted()
      paymentData = {
        payment:
          transactions: [
            {
              amount: { total: product.adjustedPriceStringNoSymbol(), currency: 'USD' }
              item_list: {
                items: [{
                  sku: product.id
                  name: product.translateName()
                  quantity: 1
                  price: product.adjustedPriceStringNoSymbol()
                  currency: 'USD'
                }]
              }
              description: description # Is this what shows up on their credit card, or so? TODO: Translate?
            }
          ]
      }
      return actions.payment.create paymentData
    # onAuthorize() is called when the buyer approves the payment
    onAuthorize: (data, actions) ->
      # Pass the payment info along, so we can tell the server to execute it
      return actions.payment.get().then((payment) ->
        onPaymentComplete(payment)
      )
  }, options.payPalOptions), buttonContainerID)

module.exports = {
  loadPayPal
  makeButton
}
