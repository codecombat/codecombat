
// Unset someone with a teacher role. Remove trial requests, set role to student or nothing
// depending on if they're in any classrooms.

// Usage
// ---------------
// In mongo shell
//
// > db.loadServerScripts();
// > deteacher('some@email.com');

var deteacher = function deteacher(email) {
  var user = db.users.findOne({emailLower: email.toLowerCase()});
  if (!user) {
    print('User not found');
    return;
  }
  print('Found user', user.name, user.email, user.role, user._id);
  var trialRequests = db.trial.requests.find({applicant: user._id}).toArray();
  for (var index in trialRequests) {
    var trialRequest = trialRequests[index];
    print('Delete trial request', JSON.stringify(trialRequest, null, '  '), db.trial.requests.remove({_id: trialRequest._id}, true));
  }
  var classroomCount = db.classrooms.count({members: user._id});
  if (classroomCount > 0) {
    print('Set to student', db.users.update({_id: user._id}, {$set: {role: 'student'}}));
  }
  else {
    print('Unset role', db.users.update({_id: user._id}, {$unset: {role: ''}}));
  }
};

db.system.js.save(
  {
    _id: 'deteacher',
    value: deteacher
  }
);
