var d = new Date();

db.achievements.find({}, {_id:1}).sort({_id:1}).forEach(function(achievement) {
  db.achievements.update({_id: achievement._id}, {$set: {updated: d.toISOString()}})
  print('set', achievement._id, 'to', d);
  d.setSeconds(d.getSeconds() + 1)
});
