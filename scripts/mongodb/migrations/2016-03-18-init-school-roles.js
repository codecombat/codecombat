// Removes all users with a teacher-like role from classroom membership
// Usage: copy and paste into mongo

var teacherRoles = ['teacher', 'technology coordinator', 'advisor', 'principal', 'superintendent'];

db.users.find({'role': {$in: teacherRoles}}, {_id: 1, name: 1, email: 1, role: 1}).forEach(function(user) {
    print('Updating user', JSON.stringify(user));
    print(db.classrooms.find({members: user._id}, {name: 1}).toArray().length);
    print(db.classrooms.update({members: user._id}, {$pull: {members: user._id}}, {multi: true}));
});


// Finds all members of classrooms, sets their role to 'student' if they do not already have a role
// Usage: copy and paste into mongo

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