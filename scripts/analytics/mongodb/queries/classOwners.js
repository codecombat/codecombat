// Latest class owners (teachers)
// Course instance owners assumed to be teachers unless hourOfCode=1

// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>

var startDay = '2015-10-01';
var endDay = '2016-10-01';
print('Date range:', startDay, endDay);
var userIDs = getClassOwners(startDay, endDay);
print('Class owners found:', userIDs.length);
var userEmails = getUserEmails(userIDs);
print('User emails found:', userEmails.length);
for (var i = 0; i < userEmails.length; i++) {
  print(userEmails[i]);
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

function getClassOwners(startDay, endDay) {
  var userIDs = [];
  var startObj = objectIdWithTimestamp(ISODate(startDay + "T00:00:00.000Z"));
  var endObj = objectIdWithTimestamp(ISODate(endDay + "T00:00:00.000Z"))
  var cursor = db.classrooms.find(
    {$and:
      [
        {_id: {$gte: startObj}},
        {_id: {$lt: endObj}}
      ]
    },
    {ownerID: 1}
  );

  while (cursor.hasNext()) {
    var myDoc = cursor.next();
    if (myDoc.ownerID) {
      userIDs.push(myDoc.ownerID);
    }
    else {
      print('No classroom owner!');
      printjson(myDoc);
      break;
    }
  }

  cursor = db.course.instances.find(
    {$and:
      [
        {_id: {$gte: startObj}},
        {_id: {$lt: endObj}}
      ]
    },
    {hourOfCode: 1, ownerID: 1}
  );
  while (cursor.hasNext()) {
    var myDoc = cursor.next();
    if (myDoc.hourOfCode) continue;
    if (myDoc.ownerID) {
      userIDs.push(myDoc.ownerID);
    }
    else {
      print('No course.instance owner!');
      printjson(myDoc);
      break;
    }
  }

  return userIDs;
}

function getUserEmails(userIDs) {
  var cursor = db['users'].find({_id: {$in: userIDs}}, {emailLower: 1});

  var userEmails = [];
  while (cursor.hasNext()) {
    var myDoc = cursor.next();
    if (myDoc.emailLower) {
      userEmails.push(myDoc.emailLower);
    }
  }
  userEmails.sort()
  return userEmails;
}
