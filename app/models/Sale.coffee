CocoModel = require('./CocoModel')

module.exports = class Sale extends CocoModel
  @className: "Sale"
  urlRoot: "/db/sale"
  @schema: require 'schemas/models/sale.schema'
  
  @makeFor: (toSell) ->
    price = toSell.get('gems') ? 0
    
    # Can't sell items that are free
    if price <= 0
      return
    
    sale = new Sale({
      recipient: me.id
      seller: me.id
      sold: {
        original: toSell.get('original')
        collection: _.string.underscored toSell.constructor.className
      }
    })