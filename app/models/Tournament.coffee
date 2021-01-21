CocoModel = require './CocoModel'


mmodule.exports = class Tournament extends CocoModel
  @className: 'Tournament'
  @schema: require 'schemas/models/tournament'
  urlRoot: '/db/tournament'
  editableByArtisans: true
