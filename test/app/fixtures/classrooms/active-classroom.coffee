Classroom = require 'models/Classroom'

module.exports = new Classroom(
  {
    _id: "active-classroom",
    name: "Teacher Zero's Classroomiest Classroom"
    members: [
      "student0",
      "student1",
      "student2",
      "student3",
    ],
    ownerID: "teacher0",
    aceConfig:
      language: 'python'
  }
)
