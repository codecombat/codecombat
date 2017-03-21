// Compare customer polls to user polls

// TODO: Only looks at subscribers currently, but it should look at other payments as well.

// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>

var scriptStartTime = new Date();
try {
  var polls = getPolls();
  var pollRecords = getPollRecords();
  var users = getUsers(Object.keys(pollRecords));

  print("Crunching the data...");
  // answerCounts format {<pollID>: {name: <name>, answers: {<answer key>: {customer: <count>, user: <count>}}, totals: {customer: <count>, user: <count>}}
  var answerCounts = {};
  for (var userID in pollRecords) {
    for (var pollID in pollRecords[userID].polls) {
      var answer = pollRecords[userID].polls[pollID];
      if (!answerCounts[pollID]) {
        answerCounts[pollID] = {
          name: polls[pollID].name,
          answers: {},
          totals: {customer: 0, user: 0}
        };
      }
      if (!answerCounts[pollID].answers[answer]) answerCounts[pollID].answers[answer] = {customer: 0, user: 0};
      if (isCustomer(users[userID])) {
        answerCounts[pollID].answers[answer].customer++;
        answerCounts[pollID].totals.customer++;
      }
      else {
        answerCounts[pollID].answers[answer].user++;
        answerCounts[pollID].totals.user++;
      }
    }
  }

  for (var pollID in answerCounts) {
    var pollName = answerCounts[pollID].name;
    print(pollName);
    var customerTotal = answerCounts[pollID].totals.customer;
    var userTotal = answerCounts[pollID].totals.user;
    for (var answer in answerCounts[pollID].answers) {
      var customerCount = answerCounts[pollID].answers[answer].customer;
      var customerPercentage = parseFloat(customerCount) / customerTotal;
      // customerPercentage = (customerPercentage * 100).toFixed(2);
      var userCount = answerCounts[pollID].answers[answer].user;
      var userPercentage = parseFloat(userCount) / userTotal;
      // userPercentage = (userPercentage * 100).toFixed(2);
      print(answer + "\t" + customerCount + "\t" + customerTotal + "\t" + customerPercentage + "\t" + userCount + "\t" + userTotal + "\t" + userPercentage);
    }
  }
}
catch(err) {
  log("ERROR: " + err);
  printjson(err);
}
finally {
  log("Script runtime: " + (new Date() - scriptStartTime));
}

function getPolls()
{
  print("Fetching polls...");
  var polls = {};
  var cursor = db.polls.find({}, {name: 1});
  while (cursor.hasNext()) {
    var doc = cursor.next();
    polls[doc._id.valueOf()] = doc;
  }
  return polls;
}

function getPollRecords()
{
  print("Fetching poll records...");
  var pollRecords = {};
  var cursor = db['user.polls.records'].find({}, {polls: 1, user: 1});
  while (cursor.hasNext()) {
    var doc = cursor.next();
    pollRecords[doc.user] = doc;
  }
  return pollRecords;
}

function getUsers(userIDs)
{
  print("Fetching users...");
  var userObjectIds = [];
  for (var i = 0; i < userIDs.length; i++) {
    userObjectIds.push(ObjectId(userIDs[i]));
  }
  var users = {};
  var cursor = db.users.find({$and: [{_id: {$in: userObjectIds}}, {stripe: {$exists: true}}]}, {stripe: 1});
  while (cursor.hasNext()) {
    var doc = cursor.next();
    users[doc._id.valueOf()] = doc;
  }
  return users;
}

// *** Helper functions ***

function log(str) {
  print(new Date().toISOString() + " " + str);
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

function isCustomer(user) {
  if (!user) return false;
  var stripe = user.stripe;
  if (!stripe) return false;
  if (stripe.sponsorID || stripe.subscriptionID || stripe.free === true) return true;
  if (typeof stripe.free === 'string' && new Date() < new Date(stripe.free)) return true;
  return false;
}
