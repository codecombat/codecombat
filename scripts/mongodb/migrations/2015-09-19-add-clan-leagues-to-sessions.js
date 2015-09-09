// Add clan leagues to sessions
// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>
//
// It just goes through all users in clans, then adds their clans to all their multiplayer sessions.

migrateClans();

function migrateClans() {
  print("Adding clan leagues to sessions...");
  var cursor = db.users.find({emailLower: {$exists: true}, clans: {$exists: true}}, {clans: 1, name: 1});
  print("Users with clans found: " + cursor.count());
  var users = cursor.toArray();
  var arenas = [
    "5442ba0e1e835500007eb1c7",
    "550363b4ec31df9c691ab629",
    "5469643c37600b40e0e09c5b",
    "54b83c2629843994803c838e",
    "544437e0645c0c0000c3291d"
  ];
  users.forEach(function (user, userIndex) {
    var leagues = [];
    for (var i = 0; i < user.clans.length; ++i) {
      leagues.push({leagueID: user.clans[i] + '', stats: {standardDeviation: 25 / 3, numberOfWinsAndTies: 0, numberOfLosses: 0, totalScore: 10, meanStrength: 25}});
    };
    //var sessions = db.level.sessions.find({creator: user._id + '', 'level.original': {$in: arenas}, submitted: true}, {clans: 1}).toArray();
    //print("Found sessions", sessions, "for user", user._id, user.name, 'who has clans', user.clans.join(', '));
    //print("Going to set leagues to...")
    //printjson(leagues);
    var conditions = {creator: user._id + '', 'level.original': {$in: arenas}, submitted: true};
    var operations = {$set: {leagues: leagues}};
    var result = db.level.sessions.update(conditions, operations, {multi: true});
    if (userIndex % 1000 === 0)
      print("Done", userIndex, "\tof", users.length, "users.");
  });
  print("Done.");
}
