CocoModel = require './CocoModel'

module.exports = class ProductModel extends CocoModel
  @className: 'Product'
  @schema: require 'schemas/models/product.schema'
  urlRoot: '/db/products'

  priceStringNoSymbol: -> (@get('amount') / 100).toFixed(2)

  purchase: (token, options={}) ->
    options.url = _.result(@, 'url') + '/purchase'
    options.method = 'POST'
    options.data ?= {}
    options.data.token = token.id
    options.data.timestamp = new Date().getTime()
    options.data = JSON.stringify(options.data)
    options.contentType = 'application/json'
    return $.ajax(options)
