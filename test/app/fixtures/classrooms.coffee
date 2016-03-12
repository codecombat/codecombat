Classroom = require 'models/Classroom';
Classrooms = require 'collections/Classrooms';

module.exports = new Classrooms([
  new Classroom({
    _id: "classroom0",
    members: [
      "student0",
      "student1",
      "student2",
      "student3",
    ],
    "ownerID": "teacher0",
  }),
])
