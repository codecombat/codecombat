// Find classrooms referencing invalid courses

// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>

print("Finding classrooms..");
var courseIDMap = {};
db.classrooms.find({}, {name: 1, courses: 1}).toArray().forEach(function (classroom) {
  for (var i = 0; i < classroom.courses.length; i++) {
    courseIDMap[classroom.courses[i]._id.valueOf()] = true;
  }
});

var courseIDs = [];
for (var courseID in courseIDMap) {
  print(courseID);
  courseIDs.push(ObjectId(courseID));
}
print("Unique courses referenced from classrooms: " + courseIDs.length);

print("Finding referenced courses..");
var foundMap = {};
db.courses.find({_id: {$in: courseIDs}}).toArray().forEach(function (course) {
  foundMap[course._id.valueOf()] = true;
});

print("Finding invalid courses and their classrooms..");
for (var courseID in courseIDMap) {
  if (!foundMap[courseID]) {
    print("Missing course: " + courseID);
    db.classrooms.find({'courses._id': ObjectId(courseID)}, {name: 1}).toArray().forEach(function (classroom) {
      print("Missing classroom: " + classroom._id.valueOf() + " " + classroom.name);
    });
  }
}
