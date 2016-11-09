mongoose = require('mongoose')
config = require '../../server_config'
co = require 'co'
ProductSchema = new mongoose.Schema({}, {strict: false,read:config.mongo.readpref})

ProductSchema.index({name: 1}, {name: 'name index'})

ProductSchema.statics.findBasicSubscriptionForUser = co.wrap (user) ->
  basicProductName = 'basic_subscription'
  if country = user.get 'country'
    countrySpecificProductName = "#{country}_basic_subscription"
    if countrySpecificProduct = yield @findOne {name: countrySpecificProductName}
      return countrySpecificProduct
  product = yield @findOne {name: basicProductName}
  return product

module.exports = mongoose.model('product', ProductSchema)
