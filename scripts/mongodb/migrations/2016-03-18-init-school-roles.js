// Usage: copy and paste into mongo


// Set all users with trial requests to a teacher or teacher-like role, depending on trial request.

var project = {role:1, name:1, email:1, permissions: 1};

db.trial.requests.find().forEach(function(trialRequest) {
    print('Inspecting trial request', trialRequest._id);
    var role = trialRequest.properties.role || 'teacher';
    var user = null;
    if(!trialRequest.applicant) {
        print('\tNO APPLICANT INCLUDED', JSON.stringify(trialRequest));
        if(!trialRequest.properties.email) {
            print('\tNO EMAIL EITHER');
            return;
        }
        user = db.users.findOne({emailLower: trialRequest.properties.email.toLowerCase()}, project);
        if(!user) {
            print('\tUSER WITH EMAIL NOT FOUND, CONTINUE');
            return;
        }
        else {
            print("\tOKAY GOT USER, UPDATE TRIAL REQUEST", JSON.stringify(user));
            db.trial.requests.update({_id: trialRequest._id}, {$set: {applicant: user._id}});
        }
    }
    else {
        user = db.users.findOne({_id: trialRequest.applicant}, project);
    }
    if (!user.role && (user.permissions||[]).indexOf('admin') === -1) {
        print('\tUpdating', JSON.stringify(user), 'to', role);
        print(db.users.update({_id: user._id}, {$set: {role: role}}));
    }
});

// Unset all teacher-like roles for users without a trial request.
// AND removes all remaining users with a teacher-like role from classroom membership (after conversion period)

var hasTrialRequest = {};
var teacherRoles = ['teacher', 'technology coordinator', 'advisor', 'principal', 'superintendent'];

db.trial.requests.find().forEach(function(trialRequest) {
    if(!trialRequest.applicant) { return; }
    hasTrialRequest[trialRequest.applicant.str] = true;
});
print(Object.keys(hasTrialRequest).length);

db.users.find({'role': {$in: teacherRoles}}, {_id: 1, name: 1, email: 1, role: 1}).forEach(function(user) {
    print('Got user with teacher role', user._id);
    if (!hasTrialRequest[user._id.str]) {
        print('\tUnset role', JSON.stringify(user));
        db.users.update({_id: user._id}, {$unset: {role: ''}});
    }
    else {
        return; // TODO: Run when we've moved completely to separate user roles
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
    print('Updating for classroom', classroom._id, 'with members', classroom.members.length);
    for (var i in classroom.members) {
        var memberID = classroom.members[i];
        print('\tupdating member', memberID);
        print(db.users.update({_id: memberID, role: {$exists: false}}, {$set: {role: 'student'}}));
    }
});
