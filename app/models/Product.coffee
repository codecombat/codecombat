CocoModel = require './CocoModel'

module.exports = class ProductModel extends CocoModel
  @className: 'Product'
  @schema: require 'schemas/models/product.schema'
  urlRoot: '/db/products'
