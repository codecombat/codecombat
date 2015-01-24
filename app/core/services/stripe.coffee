publishableKey = if application.isProduction() then 'pk_live_27jQZozjDGN1HSUTnSuM578g' else 'pk_test_zG5UwVu6Ww8YhtE9ZYh0JO6a'
  
module.exports = handler = StripeCheckout.configure({
  key: publishableKey
  name: 'CodeCombat'
  email: me.get('email')
  image: '/images/pages/base/logo_square_250.png'
  token: (token) ->
    Backbone.Mediator.publish 'stripe:received-token', { token: token }
})