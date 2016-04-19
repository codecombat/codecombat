var classrooms = db.classrooms.find();
classrooms.forEach(function (classroom) {
  printjson(classroom.members);
  classroom.members.forEach(function (userID) {
    var user = db.users.findOne({ _id: userID }, { deleted: true });
    if (user.deleted) {
      db.classrooms.update(
        { _id: classroom._id },
        {
          $addToSet: { deletedMembers: userID },
          $pull: { members: userID },
        },
      );
    }
  });
});
