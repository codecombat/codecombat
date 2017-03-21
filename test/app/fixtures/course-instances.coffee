CourseInstances = require 'collections/CourseInstances'

module .exports = new CourseInstances([
  {
    _id: "instance0"
    courseID: "course0",
    classroomID: "active-classroom"
    ownerID: "teacher1"
    members: (require 'test/app/fixtures/students').map('id')
  },
])
