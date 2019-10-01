CourseInstance = require 'models/CourseInstance'
CocoCollection = require 'collections/CocoCollection'

module.exports = class CourseInstances extends CocoCollection
  model: CourseInstance
  url: '/db/course_instance'
  
  fetchByOwner: (ownerID, options={}) ->
    ownerID = ownerID.id or ownerID # handle if they pass in a user
    options.data ?= {}
    options.data.ownerID = ownerID
    @fetch(options)

  fetchForClassroom: (classroomID, options={}) ->
    classroomID = classroomID.id or classroomID # handle if they pass in a user
    options.data ?= {}
    options.data.classroomID = classroomID
    @fetch(options)