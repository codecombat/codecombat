publishableKey = if application.isProduction() then 'pk_live_27jQZozjDGN1HSUTnSuM578g' else 'pk_test_zG5UwVu6Ww8YhtE9ZYh0JO6a'

module.exports = handler = StripeCheckout.configure({
  key: publishableKey
  name: 'CodeCombat'
  email: me.get('email')
  image: "https://codecombat.com/images/pages/base/logo_square_250.png"
  token: (token) ->
    console.log 'trigger?', handler.trigger
    handler.trigger 'received-token', { token: token }
    Backbone.Mediator.publish 'stripe:received-token', { token: token }
  locale: 'auto'
})

_.extend(handler, Backbone.Events)