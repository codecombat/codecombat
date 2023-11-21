CocoModel = require './CocoModel'

module.exports = class MandateModel extends CocoModel
  @className: 'Mandate'
  @schema: require 'schemas/models/mandate.schema'
  urlRoot: '/db/mandate'
