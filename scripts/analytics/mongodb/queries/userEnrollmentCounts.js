// Print out user enrollment counts by type

// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>

// NOTE: A given user only contributes to one enrollment type (e.g. used a paid, then not counted for trial)

var scriptStartTime = new Date();
var startDay = '2015-11-24';
var endDay = '2015-12-15';  // Not inclusive
var startDate = ISODate(startDay + "T00:00:00.000Z");
var endDate = ISODate(endDay + "T00:00:00.000Z");
print(startDay, 'up to', endDay);

var userEnrollmentsMap = {};
db.prepaids.find({type: 'course'}, {creator: 1, 'properties': 1, redeemers: 1}).forEach(function (doc) {
  var userID = doc.creator.valueOf();
  if (!userEnrollmentsMap[userID]) userEnrollmentsMap[userID] = {endDate: 0, paid: 0, trial: 0};

  if (doc.redeemers) {
    for (var i = 0; i < doc.redeemers.length; i++) {
      if (doc.redeemers[i].date < startDate || doc.redeemers[i].date > endDate) continue;
      if (doc.properties && doc.properties.endDate) {
        userEnrollmentsMap[userID].endDate++;
      }
      else if (doc.properties && doc.properties.trialRequestID) {
        userEnrollmentsMap[userID].trial++;
      }
      else {
        userEnrollmentsMap[userID].paid++;
      }
    }
  }
});

var enrollmentCounts = {endDate: 0, paid: 0, trial: 0};
for (var userID in userEnrollmentsMap) {
  if (userEnrollmentsMap[userID].paid > 0) {
    enrollmentCounts.paid += userEnrollmentsMap[userID].paid;
  }
  else if (userEnrollmentsMap[userID].endDate > 0) {
    enrollmentCounts.endDate += userEnrollmentsMap[userID].endDate;
  }
  else {
    enrollmentCounts.trial += userEnrollmentsMap[userID].trial;
  }
}

print(enrollmentCounts.paid, '\tPaid enrollments used');
print(enrollmentCounts.endDate, '\tTerminal enrollments used');
print(enrollmentCounts.trial, '\tTrial enrollments used');

log("Script runtime: " + (new Date() - scriptStartTime));


// *** Helper functions ***

function log(str) {
  print(new Date().toISOString() + " " + str);
}
