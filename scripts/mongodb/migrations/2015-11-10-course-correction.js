var counts = {
  hasClassroom: 0,
  isOwn: 0,
  migrated: 0
};

// script for generating codes
// JSON.stringify(_.unique(_.map(_.range(1000), function() { return _.sample("abcdefghijklmnopqrstuvwxyz0123456789", 8).join('') })))
var codes = 
db.course.instances.find().forEach(function(courseInstance) {
  if(courseInstance.classroomID) {
    counts.hasClassroom += 1;
    return;
  }
  if(courseInstance.ownerID && courseInstance.members && courseInstance.ownerID.equals(courseInstance.members[0]) && courseInstance.members.length === 1) {
    counts.isOwn += 1;
    return;
  }

  var id = ObjectId();

  var newClassroom = {
    members: courseInstance.members,
    ownerID: courseInstance.ownerID,
    description: courseInstance.description,
    name: courseInstance.name,
    code: codes.pop(),
    _id: id
  };
  print('migrating', JSON.stringify(newClassroom, null, '\t'));
  db.classrooms.save(newClassroom);
  courseInstance.classroomID = id;
  db.course.instances.save(courseInstance);
});
