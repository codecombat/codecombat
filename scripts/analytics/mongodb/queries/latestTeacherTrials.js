/* global ISODate */
// Latest approved teacher trial requests

// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>

var startDay = '2015-11-01';
var endDay = '2016-01-01';
print('Date range:', startDay, 'up to', endDay);

var users = getUsers(startDay, endDay);
print('Teachers found:', users.length);
print("User Id\tStudent Count\tTrial Type\tEmail\tName\tSchool");
for (var i = 0; i < users.length; i++) {
  if (users[i].schoolName) {
    print(users[i].id, '\t', users[i].studentCount, '\t', users[i].type, '\t', users[i].email, '\t', users[i].name, '\t', users[i].schoolName);
  }
}

function getUsers(startDay, endDay) {
  var cursor, doc, userID;
  
  // Find approved trial requests
  var startObj = objectIdWithTimestamp(ISODate(startDay + "T00:00:00.000Z"));
  var endObj = objectIdWithTimestamp(ISODate(endDay + "T00:00:00.000Z"))
  cursor = db['trial.requests'].find(
    {$and:
      [
        {_id: {$gte: startObj}},
        {_id: {$lt: endObj}},
        {status: 'approved'}
      ]
    },
    {applicant: 1, type: 1}
  );

  var userIDs = [];
  var userTrialTypeMap = {};
  var orphanedTrialRequests = [];
  while (cursor.hasNext()) {
    doc = cursor.next();
    if (doc.applicant) {
      userIDs.push(doc.applicant);
      userID = doc.applicant.valueOf();
      if (!userTrialTypeMap[userID] || userTrialTypeMap[userID] !== 'course') userTrialTypeMap[userID] = doc.type;
    }
    else {
      orphanedTrialRequests.push(doc._id);
    }
  }

  // May have orphaned trial requests due to previous external import of requests from Google form
  if (orphanedTrialRequests.length > 0) {
    cursor = db.prepaids.find({'properties.trialRequestID': {$in: orphanedTrialRequests}}, {creator: 1});
    while (cursor.hasNext()) {
      doc = cursor.next();
      if (doc.creator) {
        userIDs.push(doc.creator);
        userID = doc.creator.valueOf();
        if (!userTrialTypeMap[userID] || userTrialTypeMap[userID] !== 'course') userTrialTypeMap[userID] = doc.type;
      }
      else {
        print('No creator!');
        printjson(doc);
        break;
      }
    }
  }

  // Find user class sizes
  var userClassroomStudentsMap = {};
  cursor = db.classrooms.find({ownerID: {$in: userIDs}}, {members: 1, ownerID: 1});
  while (cursor.hasNext()) {
    doc = cursor.next();
    if (doc.members) {
      userID = doc.ownerID.valueOf();
      if (!userClassroomStudentsMap[userID]) userClassroomStudentsMap[userID] = 0;
      userClassroomStudentsMap[userID] = doc.members.length;
    }
  }

  // Build user data
  var users = [];
  cursor = db['users'].find({$and: [{_id: {$in: userIDs}}, {deleted: {$exists: false}}, {anonymous: false}]}, {emailLower: 1, name: 1, schoolName: 1});
  while (cursor.hasNext()) {
    doc = cursor.next();
    userID = doc._id.valueOf();
    var userData = {
      id: userID,
      email: doc.emailLower,
      name: doc.name || "",
      schoolName: doc.schoolName || "",
      studentCount: userClassroomStudentsMap[userID] || 0,
      type: userTrialTypeMap[userID]
    };
    users.push(userData);
  }

  users.sort(function(a, b) {
    if (a.studentCount > b.studentCount) return -1;
    else if (a.studentCount === b.studentCount) return a.email.localeCompare(b.email);
    return 1;
  });

  return users;
}

function objectIdWithTimestamp(timestamp) {
  // Convert string date to Date object (otherwise assume timestamp is a date)
  if (typeof(timestamp) == 'string') timestamp = new Date(timestamp);
  // Convert date object to hex seconds since Unix epoch
  var hexSeconds = Math.floor(timestamp/1000).toString(16);
  // Create an ObjectId with that hex timestamp
  var constructedObjectId = ObjectId(hexSeconds + "0000000000000000");
  return constructedObjectId
}

