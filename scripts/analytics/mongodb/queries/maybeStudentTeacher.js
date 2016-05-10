// Find users that may have incorrect roles based on classroom ownership and membership

// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>

// User buckets
// Classroom owner, no role
// Classroom owner, student role
// Classroom owner, teacher role (GOOD)
// Classroom member, no role
// Classroom member, teacher role
// Classroom member, student role (GOOD)

'use strict';
const scriptStartTime = new Date();

const classrooms = db.classrooms.find({}, {ownerID: 1, members: 1}).toArray();
print(classrooms.length, "classrooms");

const userIds = [];
const teacherIds = {};
const studentIds = {};
for (var classroom of classrooms) {
  teacherIds[classroom.ownerID.valueOf()] = true;
  userIds.push(classroom.ownerID);
  for (var memberId of classroom.members) {
    studentIds[memberId.valueOf()] = true;
    userIds.push(memberId);
  }
}

print(Object.keys(teacherIds).length, "users own classrooms");
print(Object.keys(studentIds).length, "users in classrooms");
print(Object.keys(teacherIds).length + Object.keys(studentIds).length, "total");

const users = db.users.find({$and: [{_id: {$in: userIds}}, {anonymous: false}]}, {email:1, role: 1}).toArray();

const studentOwnsClassroom = [];
const teacherInClassroom = [];
const individualInClassroom = [];
const individualOwnsClassroom = [];
for (var user of users) {
  const userId = user._id.valueOf();
  if (!user.email) {
    printjson(user);
    continue;
  }
  if (hasStudentRole(user.role)) {
    if (teacherIds[userId]) {
      studentOwnsClassroom.push(user.email);
    }
  }
  else if (hasTeacherRole(user.role)) {
    if (studentIds[userId]) {
      teacherInClassroom.push(user.email);
    }
  }
  else {
    if (studentIds[userId]) {
      individualInClassroom.push(user.email);
    }
    else if (teacherIds[userId]) {
      individualOwnsClassroom.push(user.email);
    }
    else {
      print("ERROR?", userId);
      break;
    }
  }
}

print(studentOwnsClassroom.length, "Students own classroom:");
for (var email of studentOwnsClassroom) {
  print(email);
}
print(teacherInClassroom.length, "Teachers in classroom:");
for (var email of teacherInClassroom) {
  print(email);
}
print(individualInClassroom.length, "Individuals in classroom:");
for (var email of individualInClassroom) {
  print(email);
}
print(individualOwnsClassroom.length, "Individuals own classroom:");
for (var email of individualOwnsClassroom) {
  print(email);
}

print("Script runtime: " + (new Date() - scriptStartTime));

function hasTeacherRole(role) {
  return ['teacher', 'technology coordinator', 'advisor', 'principal', 'superintendent', 'parent'].indexOf(role) >= 0;
}

function hasStudentRole(role) {
  return ['student'].indexOf(role) >= 0;
}