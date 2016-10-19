mongoose = require('mongoose')
config = require '../../server_config'
ProductSchema = new mongoose.Schema({}, {strict: false,read:config.mongo.readpref})

ProductSchema.set('toObject', {
  transform: (doc, ret, options) ->
    req = options.req
    ret.amount = doc.getPriceForUserID(req.user?.id)
    return ret
  })

ProductSchema.methods.getPriceForUserID = (userID) ->
  if _.isNumber(parseInt(@get('amount')))
    return parseInt(@get('amount'))
  else if _.isArray(@get('amount')?.test_groups)
    # TODO: Use real seeded randomness
    numTestGroups = @get('amount').test_groups.length
    testGroupNumber = parseInt(req.user.id.slice(10), 16) % numTestGroups
    return @get('amount').test_groups[testGroupNumber]
  else
    return undefined

Product = mongoose.model('product', ProductSchema)

module.exports = Product
