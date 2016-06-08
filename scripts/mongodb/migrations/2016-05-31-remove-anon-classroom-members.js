// Usage: Copy and paste into mongo shell

function removeAnonymousMembers(classroom) {
  if(!classroom.members) {
    return;
  }

  print('checking classroom',
    classroom._id,
    '\n\t',
    classroom._id.getTimestamp(),
    classroom.members.length,
    'owner', classroom.ownerID);

  classroom.members.forEach(function(userID) {
    var user = db.users.findOne({_id: userID}, {anonymous:1});
    if (!user) {
      return;
    }
    if(user.anonymous) {
      print('\tRemove user', JSON.stringify(user));

      print('\t\tRemoving from course instances',
        db.course.instances.update(
          {classroomID: classroom._id},
          {$pull: {members: userID}})
      );

      print('\t\tRemoving from classroom',
        db.classrooms.update(
          {_id: classroom._id},
          {$pull: {members: userID}})
      );
    }
  });
}

var startID = ObjectId('566838b00fb44a2e00000000');
while (true) {
  var classroom = db.classrooms.findOne({_id: {$gt: startID}});
  removeAnonymousMembers(classroom);
  startID = classroom._id;
}
