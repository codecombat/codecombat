// Migrates course-kithgard-gates-style sessions to normal levels, if the user doesn't already have a session for those
// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>

var levelsDone = 0;
var levelsTotal = 0;

migrateCourseSessionsToNormalLevels();

function migrateCourseSessionsToNormalLevels() {
  print("Grabbing all course-* levels...");
  var courseLevels = db.levels.find({slug: {$regex: /^course-/}}, {original: 1, version: 1, slug: 1});
  levelsTotal = courseLevels.count();
  courseLevels.forEach(migrateSessionsForCourseLevel);
}

function migrateSessionsForCourseLevel(courseLevel) {
  ++levelsDone;
  if (courseLevel.slug == 'course-defend-orge') return;  // Haha
  if (courseLevel.slug == 'course-winding-trail') return;  // This one we actually keep the course- version
  var heroLevel = db.levels.findOne({slug: courseLevel.slug.replace(/^course-/, '')}, {original: 1, version: 1, slug: 1, name: 1});
  if (heroLevel)
    print("Got", heroLevel.slug, "for", courseLevel.slug);
  else {
    print("No matching hero level for", courseLevel.slug);
    return;
  }
  var courseSessions = db.level.sessions.find({levelID: courseLevel.slug});
  var sessionsTotal = courseSessions.count();
  var sessionsDone = 0;
  courseSessions.forEach(function(courseSession) {
    var heroSession = db.level.sessions.findOne({
      creator: courseSession.creator,
      level: {original: heroLevel.original + '', majorVersion: heroLevel.version.major}
    });
    //print("Found hero session", !!heroSession, "for course level", courseLevel.slug, "for user", courseSession.creatorName, 'looking for hero level', heroLevel.original, heroLevel.version.major);
    if (heroSession) return;  // Already had one
    courseSession.levelID = heroLevel.slug;
    courseSession.levelName = heroLevel.name;
    courseSession.level = {original: heroLevel.original + '', majorVersion: heroLevel.version.major};
    db.level.sessions.save(courseSession);
    if (!(++sessionsDone % 100)) {
      print("Done", sessionsDone, "/", sessionsTotal, "sessions for", courseLevel.slug, "--", levelsDone, "/", levelsTotal, "levels done.");
    }
  });
}
