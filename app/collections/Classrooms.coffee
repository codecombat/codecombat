Classroom = require 'models/Classroom'
CocoCollection = require 'collections/CocoCollection'

module.exports = class Classrooms extends CocoCollection
  model: Classroom
  url: '/db/classroom'

  fetchMine: (options={}) ->
    options.data ?= {}
    options.data.ownerID = me.id
    @fetch(options)