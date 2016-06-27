
// Unset someone with a student role. Remove from classrooms, unset role.

// Usage
// ---------------
// In mongo shell
//
// > db.loadServerScripts();
// > destudent('some@email.com');

var destudent = function destudent(email) {
  var user = db.users.findOne({emailLower: email.toLowerCase()});
  if (!user) {
    print('User not found');
    return;
  }
  print('Found user', user.name, user.email, user.role, user._id);
  if (user.role !== 'student') {
    print('User is not a student.');
    return;
  }
  
  print('Removing from classrooms', 
    db.classrooms.update(
      {members: user._id},
      {$pull: {members: user._id}}, 
      {multi: true}
    )
  );

  print('Removing from course instances',
    db.course.instances.update(
      {members: user._id},
      {$pull: {members: user._id}},
      {multi: true}
    )
  );

  print('Unsetting role',
    db.users.update(
      {_id: user._id},
      {$unset: {role: ''}}
    )
  );
};

db.system.js.save(
  {
    _id: 'destudent',
    value: destudent
  }
);
