// Grab course instance data for Courses v1 Beta

// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>

// TODO: order by average levels completed

function objectIdWithTimestamp(timestamp)
{
    // Convert string date to Date object (otherwise assume timestamp is a date)
    if (typeof(timestamp) == 'string') timestamp = new Date(timestamp);
    // Convert date object to hex seconds since Unix epoch
    var hexSeconds = Math.floor(timestamp/1000).toString(16);
    // Create an ObjectId with that hex timestamp
    var constructedObjectId = ObjectId(hexSeconds + "0000000000000000");
    return constructedObjectId
}

var betaStartDate = new ISODate('2015-10-08');
var minMembers = 2;

var classes = [];
var ownerIDs = [];
var cursor = db['course.instances'].find({$and: [
    {_id: {$gte: objectIdWithTimestamp(betaStartDate)}},
    {$where: 'this.members.length >= ' + minMembers}
]}).sort({_id: 1});
while (cursor.hasNext()) {
    var doc = cursor.next();
    var ownerID = doc.ownerID;
    ownerIDs.push(ownerID);
    if (!classes[ownerID.valueOf()]) classes[ownerID.valueOf()] = [];
    classes.push({
        courseID: doc.courseID,
        courseInstanceID: doc._id,
        url: 'codecombat.com/students/' + doc.courseID.valueOf() + '/' + doc._id.valueOf(),
        ownerID: doc.ownerID,
        createDate: ownerID.getTimestamp(),
        memberCount: doc.members.length,
        name: doc.name
        });
}

var userMap = {};
cursor = db.users.find({_id: {$in: ownerIDs}});
while (cursor.hasNext()) {
  var doc = cursor.next();
  if (!userMap[doc._id.valueOf()]) userMap[doc._id.valueOf()] = {};
  userMap[doc._id.valueOf()].emailLower = doc.emailLower;
  userMap[doc._id.valueOf()].name = doc.name;
}

for (var i = 0; i < classes.length; i++) {
  classes[i].email = userMap[classes[i].ownerID.valueOf()].emailLower;
}

classes.sort(function(a, b) {
  return b.memberCount - a.memberCount;
});

for (var i = 0; i < classes.length; i++) {
  // print(classes[i].url + '\t' + classes[i].memberCount + '\t' + classes[i].email + '\t' + classes[i].name);
  print(classes[i].email);
}

print(classes.length + ' course instances with at least ' + minMembers + ' members');
