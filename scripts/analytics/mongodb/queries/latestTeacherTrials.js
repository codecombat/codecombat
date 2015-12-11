// Latest teacher trial requests

// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>

var startDay = '2015-10-01';
var endDay = '2016-10-01';
print('Date range:', startDay, endDay);
var userIDs = getTrialRequestApplicants(startDay, endDay);
print('Trial request applicants found:', userIDs.length);
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

function getTrialRequestApplicants(startDay, endDay) {
  var startObj = objectIdWithTimestamp(ISODate(startDay + "T00:00:00.000Z"));
  var endObj = objectIdWithTimestamp(ISODate(endDay + "T00:00:00.000Z"))
  var cursor = db['trial.requests'].find(
    {$and:
      [
        {_id: {$gte: startObj}},
        {_id: {$lt: endObj}}
      ]
    },
    {applicant: 1}
  );

  var applicantIDs = [];
  var orphanedTrialRequests = [];
  while (cursor.hasNext()) {
    var myDoc = cursor.next();
    if (myDoc.applicant) {
      applicantIDs.push(myDoc.applicant);
    }
    else {
      orphanedTrialRequests.push(myDoc._id);
    }
  }

  // May have orphaned trial requests due to previous external import of requests from Google form
  if (orphanedTrialRequests.length > 0) {
    cursor = db.prepaids.find({'properties.trialRequestID': {$in: orphanedTrialRequests}}, {creator: 1});
    while (cursor.hasNext()) {
      var myDoc = cursor.next();
      if (myDoc.creator) {
        applicantIDs.push(myDoc.creator);
      }
      else {
        print('No creator!');
        printjson(myDoc);
        break;
      }
    }
  }

  return applicantIDs;
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
