CocoModel = require './CocoModel'
schema = require 'schemas/models/branch.schema'
CocoCollection = require 'collections/CocoCollection'

module.exports = class Branch extends CocoModel
  @className: 'Branch'
  @schema: schema
  urlRoot: '/db/branches'
