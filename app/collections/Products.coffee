CocoCollection = require './CocoCollection'
Product = require 'models/Product'

module.exports = class Products extends CocoCollection
  model: Product
  url: '/db/products'
  
  getByName: (name) -> @findWhere { name: name }