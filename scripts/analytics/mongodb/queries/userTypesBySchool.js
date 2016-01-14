/* global printjson */
/* global db */
// Find user type counts by school

// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>

// TODO: include data for users with unknown school

var scriptStartTime = new Date();

var toString = Object.prototype.toString;
var _ = {
  isString: function (obj) {
    return toString.call(obj) == '[object String]';
  }
};

var printLineMax = 40;

var schoolTypes = ['courses paid', 'courses trial', 'courses free', 'campaign paid', 'campaign trial', 'campaign free'];

var schoolTypeCounts = getSchoolTypeCounts();

schoolTypeCounts.sort(function(a, b) {
  if (a['courses paid'] > b['courses paid']) return -1;
  else if (a['courses paid'] === b['courses paid'] && a['courses trial'] > b['courses trial']) return -1;
  else if (a['courses paid'] === b['courses paid'] && a['courses trial'] == b['courses trial'] && a['courses free'] > b['courses free']) return -1;
  else if (a['courses paid'] === b['courses paid'] && a['courses trial'] == b['courses trial'] && a['courses free'] === b['courses free'] && a['campaign paid'] > b['campaign paid']) return -1;
  else if (a['courses paid'] === b['courses paid'] && a['courses trial'] == b['courses trial'] && a['courses free'] === b['courses free'] && a['campaign paid'] === b['campaign paid'] && a['campaign trial'] > b['campaign trial']) return -1;
  else if (a['courses paid'] === b['courses paid'] && a['courses trial'] == b['courses trial'] && a['courses free'] === b['courses free'] && a['campaign paid'] === b['campaign paid'] && a['campaign trial'] === b['campaign trial'] && a['campaign free'] > b['campaign free']) return -1;
  else if (a['courses paid'] === b['courses paid'] && a['courses trial'] == b['courses trial'] && a['courses free'] === b['courses free'] && a['campaign paid'] === b['campaign paid'] && a['campaign trial'] === b['campaign trial'] && a['campaign free'] === b['campaign free']) return 0;
  return 1;
});


print('total\tcourses paid\tcourses trial\tcourses free\tcampaign paid\tcampaign trial\tcampaign free\tschool');
for (var i = 0; i < schoolTypeCounts.length; i++) {
  var schoolData = schoolTypeCounts[i]; 
  print(schoolData['total'], '\t', schoolData['courses paid'], '\t', schoolData['courses trial'], '\t', schoolData['courses free'], '\t', schoolData['campaign paid'], '\t', schoolData['campaign trial'], '\t', schoolData['campaign free'], '\t', schoolData.schoolName);
  if (i >= printLineMax - 1) break;
}

schoolTypeCounts.sort(function(a, b) {
  if (a.total > b.total) return -1;
  else if (a.total === b.total) return 0;
  return 1;
});

print('total\tcourses paid\tcourses trial\tcourses free\tcampaign paid\tcampaign trial\tcampaign free\tschool');
for (var i = 0; i < schoolTypeCounts.length; i++) {
  var schoolData = schoolTypeCounts[i]; 
  print(schoolData['total'], '\t', schoolData['courses paid'], '\t', schoolData['courses trial'], '\t', schoolData['courses free'], '\t', schoolData['campaign paid'], '\t', schoolData['campaign trial'], '\t', schoolData['campaign free'], '\t', schoolData.schoolName);
  if (i >= printLineMax - 1) break;
}

log("Script runtime: " + (new Date() - scriptStartTime));


function getSchoolTypeCounts() {
  // Find users with school data
  log("Finding users with a school name..");
  var prepaidIDs = [];
  var userIDs = [];
  var prepaidUserMap = {};
  var userSchoolMap = {};
  var userSubscriptionMap = {};
  var cursor = db.users.find({
      $and: [
      {anonymous: false},
      {schoolName: {$exists: true}},
      {schoolName: {$ne: ''}}
      ]
    }, {coursePrepaidID: 1, schoolName: 1, stripe: 1});
  while (cursor.hasNext()) {
      var doc = cursor.next();
      var userID = doc._id.valueOf();
      if (doc.coursePrepaidID) {
        prepaidIDs.push(doc.coursePrepaidID);
        var prepaidID = doc.coursePrepaidID.valueOf();
        if (!prepaidUserMap[prepaidID]) prepaidUserMap[prepaidID] = [];
        prepaidUserMap[prepaidID].push(userID);
      }
      if (doc.stripe && (doc.stripe.sponsorID || doc.stripe.subscriptionID || _.isString(doc.stripe.free) && new Date() < new Date(doc.stripe.free))) {
        userSubscriptionMap[userID] = true; 
      }
      userIDs.push(userID);
      userSchoolMap[userID] = doc.schoolName;
  }
  log("Users with schools: " + userIDs.length);
  // printjson(userSubscriptionMap);

  // Find user types
  var userTypeMap = {};

  // courses paid: coursePrepaidID set, prepaid not trial
  // courses trial: coursePrepaidID set, prepaid has trialRequestID set
  log("Finding courses prepaids..");
  var cursor = db.prepaids.find({_id: {$in: prepaidIDs}}, {properties: 1});
  while (cursor.hasNext()) {
      var doc = cursor.next();
      var prepaidID = doc._id.valueOf();
      if (prepaidUserMap[prepaidID]) {
        var type = doc.properties && doc.properties.trialRequestID ? 'courses trial' : 'courses paid';
        for (var i = 0; i < prepaidUserMap[prepaidID].length; i++) {
          userTypeMap[prepaidUserMap[prepaidID][i]] = type;
        }
      }
      else {
        print("ERROR");
        printjson(doc);
        break;
      }
  }
  // printjson(userTypeMap);

  // courses free: class member, no coursePrepaidID not set
  log("Finding classrooms..");
  var userClassroomMap = {};
  var cursor = db.classrooms.find({}, {members: 1});
  while (cursor.hasNext()) {
    var doc = cursor.next();
    if (doc.members) {
      for (var i = 0; i < doc.members.length; i++) {
        userClassroomMap[doc.members[i].valueOf()] = true;
      }
    }
  }
  for (var i = 0; i < userIDs.length; i++) {
    if (!userTypeMap[userIDs[i]] && userClassroomMap[userIDs[i]]) {
      userTypeMap[userIDs[i]] = 'courses free';
    }
  }

  // campaign trial: has subscription and trial request
  log("Finding trial requests..");
  var cursor = db.trial.requests.find({status: 'approved'}, {applicant: 1});
  while (cursor.hasNext()) {
    var doc = cursor.next();
    if (doc.applicant) {
      var userID = doc.applicant.valueOf();
      if (!userTypeMap[userID] && userSubscriptionMap[userID]) userTypeMap[userID] = 'campaign trial';
    }
  }

  // campaign paid: has subscription, no approved trial request
  // campaign free: no other matches
  log("Setting remaining user types to campaign paid or free..");
  for (var i = 0; i < userIDs.length; i++) {
    if (!userTypeMap[userIDs[i]]) userTypeMap[userIDs[i]] = userSubscriptionMap[userIDs[i]] ? 'campaign paid' : 'campaign free';
  }

  // Tally user types per school
  var schoolTypeCountMap = {};
  for (var userID in userTypeMap) {
    var schoolName = userSchoolMap[userID];
    var type = userTypeMap[userID];
    if (!schoolTypeCountMap[schoolName]) schoolTypeCountMap[schoolName] = {};
    if (!schoolTypeCountMap[schoolName][type]) schoolTypeCountMap[schoolName][type] = 0;
    schoolTypeCountMap[schoolName][type]++;
  }

  var schoolTypeCounts = [];
  for (var schoolName in schoolTypeCountMap) {
    var schoolData = {schoolName: schoolName, total: 0};
    for (var type in schoolTypeCountMap[schoolName]) {
      schoolData[type] = schoolTypeCountMap[schoolName][type];
      schoolData.total += schoolTypeCountMap[schoolName][type];
    }
    for (var i = 0; i < schoolTypes.length; i++) {
      if (!schoolData[schoolTypes[i]]) schoolData[schoolTypes[i]] = 0;
    }
    schoolTypeCounts.push(schoolData);
  }
  log("School count: " + schoolTypeCounts.length);

  return schoolTypeCounts;
}

function log(str) {
  print(new Date().toISOString() + " " + str);
}
