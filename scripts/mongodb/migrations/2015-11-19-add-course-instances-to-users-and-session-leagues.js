// Add user.courseInstances properties and then add those to session leagues
// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>

addCourseInstancesToUsers();

function uniq(array) {
   var u = {}, a = [];
   for(var i = 0, l = array.length; i < l; ++i){
      if(u.hasOwnProperty(array[i])) {
         continue;
      }
      a.push(array[i]);
      u[array[i]] = 1;
   }
   return a;
}

function addCourseInstancesToUsers() {
  print("Adding courseInstances to users...");
  var cursor = db.course.instances.find({$where: "this.members && this.members.length > 1"}, {members: 1});
  print("CourseInstances with users found: " + cursor.count());
  var courseInstances = cursor.toArray();
  var userIDList = [];
  courseInstances.forEach(function (courseInstance, courseInstanceIndex) {
    userIDList = userIDList.concat(courseInstance.members);
    var conditions = {_id: {$in: courseInstance.members}};
    var operations = {$addToSet: {courseInstances: courseInstance._id}};
    //print('Fetching', JSON.stringify(conditions), 'with operations', JSON.stringify(operations));
    //print("... Have this many:", db.users.count(conditions));
    var result = db.users.update(conditions, operations, {multi: true});
    if (courseInstanceIndex % 100 === 0)
      print("Done", courseInstanceIndex, "\tof", courseInstances.length, "course instances.");
  });
  print("Done adding course instances to users; now going to add them to sessions for leagues.");
  addCourseInstancesToSessions(userIDList);
}

function addCourseInstancesToSessions(userIDList) {
  userIDList = uniq(userIDList);
  print("Adding courseInstance leagues to sessions for", userIDList.length, "users...");
  
  var cursor = db.users.find({_id: {$in: userIDList}, courseInstances: {$exists: true}}, {courseInstances: 1, name: 1, leagues: 1});
  print("Users with courseInstances found: " + cursor.count(), '-- supposed to have:', userIDList.length);
  var users = cursor.toArray();
  var arenas = [
    "5442ba0e1e835500007eb1c7",
    "550363b4ec31df9c691ab629",
    "5469643c37600b40e0e09c5b",
    "54b83c2629843994803c838e",
    "544437e0645c0c0000c3291d",
    "5630eab0c0fcbd86057cc2f8",
    "55de80407a57948705777e89"
  ];
  users.forEach(function (user, userIndex) {
    var sessions = db.level.sessions.find({creator: user._id + '', 'level.original': {$in: arenas}, submitted: true}).toArray();
    //print("Found sessions", sessions, "for user", user._id, user.name, 'who has courseInstances', user.courseInstances.join(', '));
    sessions.forEach(function(session, sessionIndex) {
      var leagues = session.leagues || [];
      for (var i = 0; i < user.courseInstances.length; ++i) {
        var alreadyHave = false;
        for (var j = 0; j < leagues.length; ++j)
          if (leagues[j].leagueID == user.courseInstances[i])
            alreadyHave = true;
        if (!alreadyHave)
          leagues.push({leagueID: user.courseInstances[i] + '', stats: {standardDeviation: 25 / 3, numberOfWinsAndTies: 0, numberOfLosses: 0, totalScore: 10, meanStrength: 25}});
      }
      //print("  Setting leagues to...");
      //printjson(leagues);
      session.leagues = leagues;
      db.level.sessions.save(session);
    });

    if (userIndex % 100 === 0)
      print("Done", userIndex, "\tof", users.length, "users.");
  });
  print("Done.");
}
