mongoose = require('mongoose')
config = require '../../server_config'
co = require 'co'
ProductSchema = new mongoose.Schema({}, {strict: false,read:config.mongo.readpref})
plugins = require '../plugins/plugins'
jsonSchema = require '../../app/schemas/models/product.schema'

ProductSchema.index({name: 1}, {name: 'name index'})

ProductSchema.plugin(plugins.TranslationCoveragePlugin)
ProductSchema.plugin(plugins.PatchablePlugin)

ProductSchema.statics.findBasicSubscriptionForUser = co.wrap (user) ->
  basicProductName = 'basic_subscription'
  if country = user.get 'country'
    countrySpecificProductName = "#{country}_basic_subscription"
    if countrySpecificProduct = yield @findOne {name: countrySpecificProductName}
      return countrySpecificProduct
  product = yield @findOne {name: basicProductName}
  return product

ProductSchema.statics.jsonSchema = jsonSchema

ProductSchema.statics.editableProperties = [
  'i18n',
  'i18nCoverage'
]

module.exports = mongoose.model('product', ProductSchema)
