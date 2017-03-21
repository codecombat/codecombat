var levelID = 'zero-sum';
var sessions = db.level.sessions.find({levelID: levelID, submitted: true}).toArray();
for (var i = 0; i < sessions.length; ++i) {
  var session = sessions[i];
  if (session.creatorName == 'The AI') continue;
  if (!session.submittedCode) continue;
  print("Unsubmitting " + session.creatorName + " " + session.team);
  session.submitted = false;
  db.level.sessions.save(session);
}

// // Resubmit
// var levelID = 'zero-sum';
// var sessions = db.level.sessions.find({levelID: levelID, submitted: false}).toArray();
// for (var i = 0; i < sessions.length; ++i) {
//   var session = sessions[i];
//   if (session.creatorName == 'The AI') continue;
//   if (!session.submittedCode) continue;
//   print("Resubmitting " + session.creatorName + " " + session.team);
//   session.submitted = true;  // false;
//   db.level.sessions.save(session);
// }
