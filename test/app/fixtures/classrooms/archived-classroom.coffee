Classroom = require 'models/Classroom'

module.exports = new Classroom(
  {
    _id: "classroom_archived",
    name: "Teacher Zero's Archived Classroom"
    members: [
      "student0",
      "student3",
    ],
    ownerID: "teacher0",
    aceConfig:
      language: 'python'
    archived: true
  }
)
