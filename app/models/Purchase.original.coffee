CocoModel = require('./CocoModel')

module.exports = class Purchase extends CocoModel
  @className: "Purchase"
  urlRoot: "/db/purchase"
  @schema: require 'schemas/models/purchase.schema'
  
  @makeFor: (toPurchase) ->
    purchase = new Purchase({
      recipient: me.id
      purchaser: me.id
      purchased: {
        original: toPurchase.get('original')
        collection: _.string.underscored toPurchase.constructor.className
      }
    })