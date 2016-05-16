// Print out code language usage based on level session data

// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>

const scriptStartTime = new Date();

const today = new Date().toISOString().substr(0, 10);
const numDays = 30;

const dayIncrement = 1;
const startDate = new Date();
startDate.setUTCDate(startDate.getUTCDate() - numDays);
var startDay = startDate.toISOString().substr(0, 10);
const endDate = new Date();
endDate.setUTCDate(endDate.getUTCDate() - numDays + dayIncrement);
var endDay = endDate.toISOString().substr(0, 10);
log("Start day: " + startDay);

const languages = {};
while (startDay <= today) {
  log(startDay + " " + endDay);
  const startObj = objectIdWithTimestamp(ISODate(startDay + "T00:00:00.000Z"));
  const endObj = objectIdWithTimestamp(ISODate(endDay + "T00:00:00.000Z"));
  const query = {$and: [{_id: {$gte: startObj}}, {_id: {$lt: endObj}}, {codeLanguage: {$exists: true}}]};
  const cursor = db.level.sessions.find(query, {codeLanguage: 1});
  while (cursor.hasNext()) {
    const levelSession = cursor.next();
    if (!languages[levelSession.codeLanguage]) languages[levelSession.codeLanguage] = 0
    languages[levelSession.codeLanguage]++;
  }
  startDate.setUTCDate(startDate.getUTCDate() + dayIncrement);
  startDay = startDate.toISOString().substr(0, 10);
  endDate.setUTCDate(endDate.getUTCDate() + dayIncrement);
  endDay = endDate.toISOString().substr(0, 10);
}

const languageCounts = [];
var total = 0;
for (var language in languages) {
  languageCounts.push({language: language, count: languages[language]});
  total += languages[language];
}
languageCounts.sort((a, b) => {
  if (a.count < b.count) return 1;
  if (b.count < a.count) return -1;
  return 0;
})

for (var language of languageCounts) {
  print((language.count / total * 100).toFixed(2) + "%\t" + language.count + "\t" + language.language);
}
print("Level sessions with code languages", total);

log("Script runtime: " + (new Date().getTime() - scriptStartTime.getTime()));

function objectIdWithTimestamp(timestamp) {
  // Convert string date to Date object (otherwise assume timestamp is a date)
  if (typeof(timestamp) == 'string') timestamp = new Date(timestamp);
  // Convert date object to hex seconds since Unix epoch
  const hexSeconds = Math.floor(timestamp/1000).toString(16);
  // Create an ObjectId with that hex timestamp
  const constructedObjectId = ObjectId(hexSeconds + "0000000000000000");
  return constructedObjectId
}

function log(str) {
  print(new Date().toISOString() + " " + str);
}
