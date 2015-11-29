// Adds up all concept statistics for all non-anoymous users.
// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>

var alreadyCompleted = 0;  // For simple skipping and restarting

addConceptStatsToUsers();

function addConceptStatsToUsers() {
  print("Adding concept stats to all non-anonymous users...");
  var levels = db.levels.find({slug: {$exists: true}}, {campaign: 1, slug: 1, original: 1, concepts: 1, 'state.complete': 1}).toArray();
  levels = levels.filter(function(level) { return level.campaign && level.concepts && level.concepts.length; });
  var conceptMap = {};
  levels.forEach(function(level) { conceptMap[level.original + ''] = level.concepts || []; });
  print("Got concept map for", levels.length, "levels.");
  var users = db.users.find({emailLower: {$exists: true}});
  var usersTotal = users.count();
  var usersDone = 0;
  var t0 = null;
  users.forEach(function(user) {
    if (usersDone < alreadyCompleted) return ++usersDone;
    if (!t0) t0 = new Date();  // Started processing users, so start the timer.
    user.stats = user.stats || {};
    user.stats.concepts = {};
    var sessions = db.level.sessions.find({creator: user._id + ''});
    sessions.forEach(function(session) {
      if (!session.state || !session.state.complete) return;
      var concepts = conceptMap[session.level.original + ''];
      if (!concepts) return;
      concepts.forEach(function(concept) {
        user.stats.concepts[concept] = (user.stats.concepts[concept] || 0) + 1;
      });
    });
    //print("Would say", user.name, user.email, "learned concepts", JSON.stringify(user.stats.concepts));
    db.users.save(user);
    if (++usersDone % 100 == 0) {
      var t1 = new Date();
      var elapsedSeconds = Math.round((t1 - t0) / 1000);
      var remainingSeconds = Math.round((usersTotal - usersDone) / ((usersDone - alreadyCompleted) / elapsedSeconds));
      print(usersDone, "\t/", usersTotal, "\t-- ", (100 * usersDone / usersTotal).toFixed(4) + "%\tElapsed:", toHHMMSS(elapsedSeconds), "\tRemaining:", toHHMMSS(remainingSeconds));
    }
  });
}

function toHHMMSS(rawSeconds) {
    var hours   = Math.floor(rawSeconds / 3600);
    var minutes = Math.floor((rawSeconds - (hours * 3600)) / 60);
    var seconds = rawSeconds - (hours * 3600) - (minutes * 60);
    if (hours   < 10) hours   = "0" + hours;
    if (minutes < 10) minutes = "0" + minutes;
    if (seconds < 10) seconds = "0" + seconds;
    return hours + ':' + minutes + ':' + seconds;
}
