// Usage: copy and paste into mongo


// Set all users with trial requests to a teacher or teacher-like role, depending on trial request.

var hasTrialRequest = {};

db.trial.requests.find().forEach(function(trialRequest) {
    var role = trialRequest.properties.role || 'teacher';
    var user = db.users.findOne({_id: trialRequest.applicant}, {role:1, name:1, email:1});
    print(JSON.stringify(user), JSON.stringify(trialRequest.properties), role);
    if (!user.role) {
        print(db.users.update({_id: trialRequest.applicant}, {$set: {role: role}}));
    }
    hasTrialRequest[user._id.str] = true;
});

var teacherRoles = ['teacher', 'technology coordinator', 'advisor', 'principal', 'superintendent'];

// Unset all teacher-like roles for users without a trial request.
// AND removes all remaining users with a teacher-like role from classroom membership (after conversion period)

db.users.find({'role': {$in: teacherRoles}}, {_id: 1, name: 1, email: 1, role: 1}).forEach(function(user) {
    print('Updating user', JSON.stringify(user));
    if (!hasTrialRequest.user._id.str) {
        print('\tunset role');
        //db.users.update({_id: user._id}, {$unset: {role: ''}});
    }
    else {
        var count = db.classrooms.count({members: user._id}, {name: 1});
        if (count) {
            print('\tWill remove from classrooms');
            //print(db.classrooms.update({members: user._id}, {$pull: {members: user._id}}, {multi: true}));
        }
        else {
            print('\tRole correct, in no classrooms. No action')
        }
    }
});

// Find all members of classrooms, set their role to 'student' if they do not already have a role

db.classrooms.find({}, {members: 1}).forEach(function(classroom) {
    if(!classroom.members) {
        return;
    }
    for (var i in classroom.members) {
        var memberID = classroom.members[i];
        print('updating member', memberID);
        print(db.users.update({_id: memberID, role: {$exists: false}}, {$set: {role: 'student'}}));
    } 
});