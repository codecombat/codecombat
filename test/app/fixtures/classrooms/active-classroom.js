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
    courses: [
      {
        _id: "course0",
        levels: [
          {
            original: 'level0_0'
            name: 'level0_0'
            type: 'hero'
          },
          {
            original: 'level0_1'
            name: 'level0_1'
            type: 'hero'
          },
          {
            original: 'level0_2'
            name: 'level0_2'
            type: 'hero'
          },
          {
            original: 'level0_3'
            name: 'level0_3'
            type: 'hero'
          },
        ]
      },
      {
        _id: "course1",
        levels: []
      },
    ]
  }
)
