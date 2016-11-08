mongoose = require('mongoose')
config = require '../../server_config'
ProductSchema = new mongoose.Schema({}, {strict: false,read:config.mongo.readpref})

ProductSchema.index({name: 1}, {name: 'name index'})

ProductSchema.statics.findBasicSubscriptionForUser = (user) ->
  basicProductName = 'basic_subscription'
  if country = user.get 'country'
    countrySpecificProductName = "#{country}_basic_subscription"
    if countrySpecificProduct = yield @findOne {name: countrySpecificProductName}
      return countrySpecificProduct
  return yield @findOne {name: basicProductName}

module.exports = mongoose.model('product', ProductSchema)
