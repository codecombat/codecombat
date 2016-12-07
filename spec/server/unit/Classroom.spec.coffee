mongoose = require 'mongoose'
Classroom = require '../../../server/models/Classroom'
CourseInstance = require '../../../server/models/CourseInstance'

describe 'server/models/Classroom', ->
  
  describe '.toObject({req, includeEnrolled})', ->
    
    it 'embeds provided courseInstance members lists in the returned object', ->
      studentId = mongoose.Types.ObjectId()
      courseIds = _.times(2, -> mongoose.Types.ObjectId())
      classroom = new Classroom({
        courses: _.map(courseIds, (_id) -> { _id })
      }) 
      courseInstances = [
        new CourseInstance({members: [studentId], courseID: courseIds[0]})
      ]
      classroomObject = classroom.toObject({includeEnrolled: courseInstances})
      
      # first course should have the member list from the created course instance
      expect(classroomObject.courses[0].enrolled.length).toBe(1)
      expect(classroomObject.courses[0].enrolled[0].equals(studentId)).toBe(true)
      
      # the second course should have created a default empty array
      expect(classroomObject.courses[1].enrolled.length).toBe(0)
