var classrooms = db.classrooms.find({ "courses.levels": {$elemMatch: {slug: "true-names", primerLanguage: {$exists: true}}} })
var numFixed = 0;
var numToFix = classrooms.count()
classrooms.forEach(function(classroom) {
  classroom.courses.forEach(function(course) {
    course.levels.forEach(function(level) {
      if (level.slug === 'true-names' && level.primerLanguage) {
        delete level.primerLanguage;
      }
    })
  })
  numFixed += 1;
  print('Fixing classroom ' + numFixed + '/' + numToFix);
  db.classrooms.update({ _id: classroom._id }, classroom);
})
