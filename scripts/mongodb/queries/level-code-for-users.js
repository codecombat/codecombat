// Finds all human ladder sessions for given usernames and grab the code per player.

var usernames = ['Nick'];
usernames = usernames.map(function(u) { return u.toLowerCase(); });
var levelID = 'ace-of-coders';
usernames.sort(Math.random);
var users = db.users.find({nameLower: {$in: usernames}, anonymous: false}).toArray();
var userIDs = [];
for (var userIndex = 0; userIndex < users.length; ++userIndex) {
  userIDs.push('' + users[userIndex]._id);
}
var sessions = db.level.sessions.find({creator: {$in: userIDs}, levelID: levelID, team: 'humans'}).toArray();
var userCode = {};
for (var i = 0; i < sessions.length; ++i) {
  var session = sessions[i];
  if (!session) continue;
  if (!session.code || !session.levelName) continue;
  userCode[session.creatorName] = session.code['hero-placeholder'].plan;
  //var anonymizedUsername = 'user' + userIDs.indexOf(session.creator);
}
for (var username in userCode) {
  print(username + "\n" + userCode[username] + "\n\n----------------------\n");
}

