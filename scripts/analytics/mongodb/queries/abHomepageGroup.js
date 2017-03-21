// abHomePageGroup A/B Results
// Test started 2016-02-03
// Main conversion actions (viewing quote requests, playing levels) tracked in Mixpanel
// This just looks at who has a trial request, and then also who created an account, based on homePageGroup

// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>

var groups = {
  '0': {name: 'control', count: 0, registeredCount: 0},
  '1': {name: 'home-with-note', count: 0, registeredCount: 0},
  '2': {name: 'new-home-student', count: 0, registeredCount: 0},
  '3': {name: 'new-home-characters', count: 0, registeredCount: 0}
};

var requests = db.trial.requests.find({created: {$gt: new Date(2016, 1, 3)}}).toArray();
var userIDs = requests.map(function(r) { return r.applicant; });
var applicants = db.users.find({_id: {$in: userIDs}}).toArray();
var counts = {};
function format(u) {
  var group = groups[u.testGroupNumber % 4];
  ++group.count;
  if (u.email)
    ++group.registeredCount;
  return [u.email || u.name || u._id + '', group.name].join('\t');
}
print(applicants.map(format).join('\n'));
print(applicants.length, "trial requests across groups:");
print(JSON.stringify(groups, null, 2));
