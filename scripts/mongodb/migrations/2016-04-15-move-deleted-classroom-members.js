load('bower_components/lodash/dist/lodash.js');
var classrooms = db.classrooms.find();
classrooms.forEach(function (classroom) {
    print('classroom', classroom._id);
    classroom.members.forEach(function (userID) {
        if (_.isString(userID)) {
            userID = ObjectId(userID);
        }
        var user = db.users.findOne({ _id: userID }, { deleted: true });
        if (user.deleted) {
            print('\tFOUND ONE', userID);
            print('\t', db.classrooms.update(
                { _id: classroom._id },
                {
                    $addToSet: { deletedMembers: userID },
                    $pull: { members: userID }
                }
            ));
        }
    });
});
