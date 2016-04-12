// Updates all sessions for a given level and classroom to match the classroom language setting.
// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>

print('Loading levels...');
var levels = [db.levels.findOne({slug: 'wakka-maul'}), db.levels.findOne({slug: 'cross-bones'})];
print('Loaded');

db.classrooms.find({'aceConfig.language': 'javascript'}).forEach(function(classroom) {
    for (var l in levels) {
        var level = levels[l];
        print('----------------------------');
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
    }
});

