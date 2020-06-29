publishableKey = if application.isProduction() then 'pk_live_27jQZozjDGN1HSUTnSuM578g' else 'pk_test_zG5UwVu6Ww8YhtE9ZYh0JO6a'

if me.isAnonymous()
  module.exports = {
    open: _.noop # for tests to spy on
    openAsync: _.noop # for tests to spy on
  }
  _.extend(module.exports, Backbone.Events)
  module.exports.makeNewInstance = _.clone(module.exports)
else if not StripeCheckout?
  module.exports = {}
  console.error "Failure loading StripeCheckout API, returning empty object."
else
  makeNewInstance = ->
    handler = StripeCheckout.configure({
      key: publishableKey
      name: 'CodeCombat'
      email: me.get('email')
      image: "https://codecombat.com/images/pages/base/logo_square_250.png"
      token: (token) ->
        handler.trigger 'received-token', { token }
        Backbone.Mediator.publish 'stripe:received-token', { token: token }
      locale: 'auto'
      zipCode: true
    })
    handler.id = _.uniqueId()
    handler.openAsync = (options) ->
      promise = new Promise((resolve, reject) ->
        handler.once('received-token', resolve)
      )
      handler.open(options)
      return promise
    _.extend(handler, Backbone.Events)
    return handler
  module.exports = makeNewInstance()
  module.exports.makeNewInstance = makeNewInstance
