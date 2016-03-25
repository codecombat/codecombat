Classroom = require 'models/Classroom';
Classrooms = require 'collections/Classrooms';

module.exports = new Classrooms([
  {
    _id: "classroom0",
    name: "Teacher Zero's Other Classroom"
    ownerID: "teacher0",
    aceConfig:
      language: 'python'
    members: []
  }

  {
    _id: "classroom1",
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
  
  {
    _id: "classroom_archived",
    name: "Teacher Zero's Archived Classroom"
    members: [
      "student0",
      "student4",
    ],
    ownerID: "teacher0",
    aceConfig:
      language: 'python'
    archived: true
  }
])
