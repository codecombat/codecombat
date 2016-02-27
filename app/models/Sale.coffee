CocoModel = require('./CocoModel')

module.exports = class Sale extends CocoModel
  @className: "Sale"
  urlRoot: "/db/sale"
  @schema: require 'schemas/models/sale.schema'
  
  @makeFor: (toSell) ->
    # Prevent the user from selling an unsellable item
    if !toSell.sellable()
      return
    
    sale = new Sale({
      recipient: me.id
      seller: me.id
      sold: {
        original: toSell.get('original')
        collection: _.string.underscored toSell.constructor.className
      }
    })