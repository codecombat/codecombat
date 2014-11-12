c = require 'schemas/schemas'

module.exports =
  'ipad:products': c.object {required: ['products']},
    products: c.array {}, 
      c.object {},
        gems: { type: 'integer' }
        price: { type: 'string' }
        id: { type: 'string' }
        
  'ipad:iap-complete': c.object {},
    gems: { type: 'integer' }
