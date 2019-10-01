Classroom = require 'models/Classroom'
Classrooms = require 'collections/Classrooms'

module.exports = new Classrooms([
  require './active-classroom'
  require './empty-classroom'
])
