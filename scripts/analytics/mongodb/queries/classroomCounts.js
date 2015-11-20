// Print out classrooms ordered by size

// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>

var userClassroomMap = {};
var cursor = db.classrooms.find({$where: 'this.members.length > 40'}, {ownerID: 1, name: 1, members: 1});
while (cursor.hasNext()) {
  var doc = cursor.next();
  var userID = doc.ownerID.valueOf();
  if (!userClassroomMap[userID]) userClassroomMap[userID] = [];
  userClassroomMap[userID].push({
    classroomID: doc._id,
    className: doc.name,
    count: doc.members.length
  });
}

var userIDs = [];
for (var userID in userClassroomMap) {
  userIDs.push(new ObjectId(userID));
}

var classrooms = [];
cursor = db.users.find({_id: {$in: userIDs}}, {email: 1});
while (cursor.hasNext()) {
  var doc = cursor.next();
  var userID = doc._id.valueOf();
  for (var i = 0; i < userClassroomMap[userID].length; i++) {
    classrooms.push({
      ownerID: userID,
      email: doc.email,
      classroomID: userClassroomMap[userID][i].classroomID,
      className: userClassroomMap[userID][i].className,
      count: userClassroomMap[userID][i].count
    });
  }
}

classrooms.sort(function(a, b) { return a.count > b.count ? -1 : 1;});
for (var i = 0; i < classrooms.length; i++) {
  print(classrooms[i].count, classrooms[i].className, classrooms[i].email, classrooms[i].classroomID.valueOf());
}
print("Total classes:", classrooms.length);
