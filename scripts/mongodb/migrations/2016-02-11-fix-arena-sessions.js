// Updates all sessions for a given level and classroom to match the classroom language setting.
// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>

// Set classroomID and levelSlug first before running!

var classroomID = ObjectId('568ac66d648b9e5100de0cca');
var levelSlug = 'wakka-maul';

var classroom = db.classrooms.findOne({_id: classroomID});
var level = db.levels.findOne({slug: levelSlug});

if(!classroom) { throw new Error('Classroom not found (should be an id)'); }
if(!level) { throw new Error('Level not found (should be a slug)'); }

print('Classroom:', classroom.name);
print('Members:', classroom.members.length);
print('Level:', level.name);

for (var i in classroom.members) {
  var member = classroom.members[i];
  var sessions = db.level.sessions.find({'level.original': level.original+'', 'creator': member+''}).toArray();
  print('  user:', member);
  for (var j in sessions) {
    var session = sessions[j];
    print('    session:', session._id, 'has language', session.codeLanguage);
    if (session.codeLanguage === classroom.aceConfig.language) {
      print('    all is well');
      continue;
    }
    print('      updating language...');
    print('      ', db.level.sessions.update({_id: session._id}, {$set: {codeLanguage: classroom.aceConfig.language}}));
  }
}
