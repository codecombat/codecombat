load('bower_components/lodash/dist/lodash.js');

var courses = db.courses.find({}).sort({_id:1}).toArray();
var ids = _.pluck(courses, 'campaignID');
var campaigns = db.campaigns.find({_id: {$in: ids}}).toArray();
var campaignMap = {};
for (var campaignIndex in campaigns) {
  var campaign = campaigns[campaignIndex];
  campaignMap[campaign._id.str] = campaign;
}
var coursesData = [];

for (var courseIndex in courses) {
  var course = courses[courseIndex];
  var courseData = { _id: course._id, levels: [] };
  var campaign = campaignMap[course.campaignID.str];
  var levels = _.values(campaign.levels);
  levels = _.sortBy(levels, 'campaignIndex');
  _.forEach(levels, function(level) {
    levelData = { original: ObjectId(level.original) };
    _.extend(levelData, _.pick(level, 'type', 'slug', 'name'));
    courseData.levels.push(levelData);
  });
  coursesData.push(courseData);
}
  
print('constructed', JSON.stringify(coursesData, null, '\t'));

db.classrooms.find({}, {courses:1}).forEach(function(classroom) {
  print('classroom', classroom._id);
  if(classroom.courses) {
    print('\tskipping');
    return;
  }
  db.classrooms.update(
    {_id: classroom._id},
    {$set: {courses: coursesData}}
  );  
});
