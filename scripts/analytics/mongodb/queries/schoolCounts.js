// Print out school user counts 

// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>


var scriptStartTime = new Date();

var cursor = db.users.find({
    $and: [
    {anonymous: false},
    {schoolName: {$exists: true}},
    {schoolName: {$ne: ''}}
    ]
}, {schoolName: 1});

var schoolCountMap = {};
while (cursor.hasNext()) {
    var doc = cursor.next();
    if (!schoolCountMap[doc.schoolName]) schoolCountMap[doc.schoolName] = 0;
    schoolCountMap[doc.schoolName]++;
}

var schoolCounts = [];
for (var schoolName in schoolCountMap) {
  schoolCounts.push({schoolName: schoolName, count: schoolCountMap[schoolName]});
}
schoolCounts.sort(function(a, b) {
  if (a.count > b.count) return -1;
  else if (a.count === b.count) return 0;
  return 1; 
});

var count = 0;
for (var i = 0; i < schoolCounts.length; i++) {
  if (schoolCounts[i].count >= 2) {
    print(++count, '\t', schoolCounts[i].count, schoolCounts[i].schoolName);
  }
}

log("Script runtime: " + (new Date() - scriptStartTime));

function log(str) {
  print(new Date().toISOString() + " " + str);
}
