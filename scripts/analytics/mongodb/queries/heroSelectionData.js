// Export csv-formatted per-student/day hero selection data

// Usage:
// mongo --quiet <address>:<port>/<database> <script file> -u <username> -p <password> --eval "var lsConn='<level session connection string,user,password>';"

'use strict';
const scriptStartTime = new Date();

const debugOutput = false;

const startObjectId = objectIdWithTimestamp(ISODate("2016-03-06T00:00:00.000Z"));
const endObjectId = objectIdWithTimestamp(ISODate("2016-11-08T00:00:00.000Z"));

// lsConn passed in as --eval parameter
const lsConnParams = lsConn.split(',');
const lsDb = connect(lsConnParams[0], lsConnParams[1], lsConnParams[2]);

db.getMongo().setReadPref('secondary');
lsDb.getMongo().setReadPref('secondary');

debug(`DEBUG: fetching students..`);
const studentMap = {};
var studentIds = [];
const thangTypeIds = [];
var query = {$and: [{"role": 'student'}, {heroConfig: {$exists: true}}, {_id: {$gte: startObjectId}}, {_id: {$lte: endObjectId}}]};
const users = db.users.find(query, {heroConfig: 1}).toArray();
for (var user of users) {
  studentMap[user._id.valueOf()] = user;
  studentIds.push(user._id);
  if (user.heroConfig.thangType) thangTypeIds.push(ObjectId(user.heroConfig.thangType));

  // if (studentIds.length >= 10000) break;
}
debug(`DEBUG: ${studentIds.length} students ${thangTypeIds.length} thang types found`);

debug(`DEBUG: fetching classrooms..`);
const studentClassroomIdsMap = {};
const classrooms = db.classrooms.find({members: {$in: studentIds}}, {members: 1}).toArray();
for (var classroom of classrooms) {
  for (var studentId of classroom.members || []) {
    if (!studentClassroomIdsMap[studentId.valueOf()]) studentClassroomIdsMap[studentId.valueOf()] = [];
    studentClassroomIdsMap[studentId.valueOf()].push(classroom._id.valueOf());
  }
}

debug(`DEBUG: fetching heroes..`);
const thangTypeMap = {};
const thangTypes = db.thang.types.find({_id: {$in: thangTypeIds}}, {name: 1}).toArray();
for (var thangType of thangTypes) {
  thangTypeMap[thangType._id.valueOf()] = thangType;
}

debug(`DEBUG: fetching level sessions..`);
const studentLevelSessionsMap = {};
studentIds = studentIds.map((id) => {return id.valueOf();});
query = {$and: [{creator: {$in: studentIds}}, {_id: {$gte: startObjectId}}, {_id: {$lte: endObjectId}}]};
// Can't $sort on dataset this size
const levelSessionData = lsDb.level.sessions.aggregate([
  {$match: query},
  {$project: {_id: 0, creator: 1, playtime: 1, day: {$dateToString: {format: "%Y-%m-%d", date: "$created"}}}},
  {$group: {
    _id: {studentId: "$creator", day: "$day"},
    numSessions: {$sum: 1},
    playtime: {$sum: "$playtime"}
  }}
]).toArray();
debug(`DEBUG: ${levelSessionData.length} level sessions`);

print("Student Id, Classroom Id, Day, Hero, Sessions, Playtime");
for (var data of levelSessionData) {
  const studentId = data._id.studentId;
  for (var classroomId of studentClassroomIdsMap[studentId] || []) {
    const heroThangTypeId = studentMap[studentId].heroConfig.thangType;
    const heroName = thangTypeMap[heroThangTypeId] ? getHeroShortName(thangTypeMap[heroThangTypeId].name || '') : '';
    print(`${studentId}, ${classroomId}, ${data._id.day}, ${heroName}, ${data.numSessions}, ${data.playtime}`);
  }
}

debug(`Script runtime: ${new Date() - scriptStartTime}`);

function debug(msg) {
  if (debugOutput) print(msg);
}

function getHeroShortName(name) {
  // Copied from ThangType.coffee
  const map = {
    "Assassin": "Ritic",
    "Captain": "Anya",
    "Champion": "Ida",
    "Master Wizard": "Usara",
    "Duelist": "Alejandro",
    "Forest Archer": "Naria",
    "Goliath": "Okar",
    "Guardian": "Illia",
    "Knight": "Tharin",
    "Librarian": "Hushbaum",
    "Necromancer": "Nalfar",
    "Ninja": "Amara",
    "Pixie": "Zana",
    "Potion Master": "Omarn",
    "Raider": "Arryn",
    "Samurai": "Hattori",
    "Sorcerer": "Pender",
    "Trapper": "Senick",
  }
  return map[name] || name;
}

function objectIdWithTimestamp(timestamp) {
  // Convert string date to Date object (otherwise assume timestamp is a date)
  if (typeof(timestamp) == 'string') timestamp = new Date(timestamp);
  // Convert date object to hex seconds since Unix epoch
  var hexSeconds = Math.floor(timestamp/1000).toString(16);
  // Create an ObjectId with that hex timestamp
  var constructedObjectId = ObjectId(hexSeconds + "0000000000000000");
  return constructedObjectId
}
