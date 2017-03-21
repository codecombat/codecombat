// Find classroom data for a specific school

// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>

// Change school name regex HERE
var schoolRegex = /schooldomain\.edu/ig;

var cursor = db.users.find({emailLower: {$regex: schoolRegex}}, {name: 1, emailLower: 1, schoolName: 1});
var userIDs = [];
var users = {};
while (cursor.hasNext()) {
    var doc = cursor.next();
    userIDs.push(doc._id);
    users[doc._id.valueOf()] = {
        email: doc.emailLower,
        name: doc.name,
        schoolName: doc.schoolName || '',
        classrooms: []
    };
}

var cursor = db.classrooms.find({ownerID: {$in: userIDs}});
while (cursor.hasNext()) {
    var doc = cursor.next();
    users[doc.ownerID.valueOf()].classrooms.push({id: doc._id.valueOf(), name: doc.name, students: doc.members.length});
}

for (var userID in users) {
    var user = users[userID];
    var studentCount = 0;
    for (var i = 0; i < user.classrooms.length; i++) {
        studentCount += user.classrooms[i].students;
    }
    if (user.classrooms.length > 0 || studentCount > 0 || user.schoolName) {
        print(userID, '\t', user.email, '\t', user.name, '\t', user.classrooms.length, '\t', studentCount, '\t', user.schoolName);
    }
}