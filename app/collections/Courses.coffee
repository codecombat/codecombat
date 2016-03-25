Course = require 'models/Course'
CocoCollection = require 'collections/CocoCollection'

module.exports = class Courses extends CocoCollection
  model: Course
  url: '/db/course'
