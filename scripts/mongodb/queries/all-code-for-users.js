// Finds all sessions for given usernames and grab all the code by level.

var usernames = ['Nick'];
usernames.sort(Math.random);
var users = db.users.find({name: {$in: usernames}, anonymous: false}).toArray();
var userIDs = [];
for (var userIndex = 0; userIndex < users.length; ++userIndex) {
  userIDs.push('' + users[userIndex]._id);
}
var sessions = db.level.sessions.find({creator: {$in: userIDs}}).toArray();
var levels = {};
for (var i = 0; i < sessions.length; ++i) {
  var session = sessions[i];
  if (!session) continue;
  if (!session.code || !session.levelName) continue;
  var userCode = {};
  if (session.teamSpells && session.team) {
    for (spellName in session.teamSpells[session.team]) {
      var spellNameElements = spellName.split('/');
      var thangName = spellNameElements[0];
      var spellName = spellNameElements[1];
      if (thangName && spellName && session.code[thangName] && session.code[thangName][spellName]) {
        userCode[thangName] = session.code[thangName] || {};
        userCode[thangName][spellName] = session.code[thangName][spellName];
      }
    }
  }
  else
    userCode = session.code;
  var anonymizedUsername = 'user' + userIDs.indexOf(session.creator);
  var codeLanguage = session.codeLanguage || 'javascript';
  levels[codeLanguage] = levels[codeLanguage] || {};
  levels[codeLanguage][session.levelName] = levels[codeLanguage][session.levelName] || {};
  levels[codeLanguage][session.levelName][anonymizedUsername] = userCode;
}
levels;

