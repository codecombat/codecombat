
// Usage: paste into mongodb

// In separating student and teacher accounts, need to see
// * Who has trial requests
// * Who owns a classroom
// * Who is in a classroom
//
// People who do not have a trial request and are both in a classroom
// and own a classroom are the most up in the air.

var creators = {};
var members = {};
db.classrooms.find({}, {ownerID:1, members:1}).forEach(function(classroom) {
  if(classroom.ownerID) { creators[classroom.ownerID.str] = false; }
  if(classroom.members) {
    for (var index in classroom.members) {
      members[classroom.members[index].str] = true;
    }
  }
});

db.trial.requests.find({}, {applicant:1}).forEach(function(trialRequest) {
  if(!trialRequest.applicant) { return; }
  creators[trialRequest.applicant.str] = true;
});

var isMemberAndNoTrialRequestCount = 0;
var noTrialRequestCount = 0;
for(var userID in creators) {
  if (!creators[userID]) {
    noTrialRequestCount += 1;
    if (members[userID]) {
      isMemberAndNoTrialRequestCount += 1;
    }
  }
}
print('count', count);
