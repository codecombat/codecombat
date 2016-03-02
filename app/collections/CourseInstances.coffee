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

  getByCourseAndClassroom: (courseID, classroomID) ->
    courseID = courseID.id or courseID
    classroomID = classroomID.id or classroomID
    _.find @models, (courseInstance) ->
      courseInstance.get('courseID') == courseID and
        courseInstance.get('classroomID') == classroomID

  #TODO: Only keep this if I actually use it
  getAllByClassroom: (classroomID) ->
    classroomID = classroomID.id or classroomID
    _.filter @models, (courseInstance) ->
      courseInstance.get('classroomID') == classroomID