// Latest enabled teacher trial requests

// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>

var startDay = '2015-09-01';
var endDay = '2015-10-01';
print('Date range:', startDay, endDay);
var prepaidCodes = getPrepaidCodes(startDay, endDay);
print('Prepaid Codes found:', prepaidCodes.length);
var userIDs = getEnabledUserIDs(prepaidCodes);
print('Enabled users found:', userIDs.length);
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

function getPrepaidCodes(startDay, endDay) {
  var startObj = objectIdWithTimestamp(ISODate(startDay + "T00:00:00.000Z"));
  var endObj = objectIdWithTimestamp(ISODate(endDay + "T00:00:00.000Z"))
  var cursor = db['trial.requests'].find(
    {$and:
      [
        {'prepaidCode': {$exists: true}},
        {_id: {$gte: startObj}},
        {_id: {$lt: endObj}}
      ]
    },
    {prepaidCode: 1}
  );

  var prepaidCodes = [];
  while (cursor.hasNext()) {
    var myDoc = cursor.next();
    prepaidCodes.push(myDoc.prepaidCode);
  }

  return prepaidCodes;
}

function getEnabledUserIDs(prepaidCodes) {
  var cursor = db['prepaids'].find(
    {$and:
      [
        {code: {$in: prepaidCodes}},
        {redeemers: {$exists: true}},
        {$where: 'this.redeemers.length > 0'}
      ]
    },
    {redeemers: 1}
  );

  var userIDs = [];
  while (cursor.hasNext()) {
    var myDoc = cursor.next();
    userIDs.push(myDoc.redeemers[0].userID);
  }

  return userIDs;
}

function getUserEmails(userIDs) {
  var cursor = db['users'].find({_id: {$in: userIDs}}, {emailLower: 1});

  var userEmails = [];
  while (cursor.hasNext()) {
    var myDoc = cursor.next();
    userEmails.push(myDoc.emailLower);
  }
  userEmails.sort()
  return userEmails;
}
