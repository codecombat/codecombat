// Print out campaign drop-off rates
// Drop off: last started or finished level event
// Adjust startDate below for different timeframe than last 7 days.

// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>

// Ignores the order at which levels are completed
// Ignores level skipping

// TODO: Is our overall drop-off rate correct?
// TODO: What's the right time frame for this data?

// TODO: Calculate completion rates per-level, and campaign overall

var today = new Date();
today = today.toISOString().substr(0, 10);
print("Today is " + today);

var todayMinus6 = new Date();
todayMinus6.setUTCDate(todayMinus6.getUTCDate() - 6);
var startDate = todayMinus6.toISOString().substr(0, 10) + "T00:00:00.000Z";
// startDate = "2014-12-31T00:00:00.000Z";
print("Start date is " + startDate)
// var endDate = "2015-01-06T00:00:00.000Z";
// print("End date is " + endDate)

function objectIdWithTimestamp(timestamp)
{
  // Convert string date to Date object (otherwise assume timestamp is a date)
  if (typeof(timestamp) == 'string') timestamp = new Date(timestamp);
  // Convert date object to hex seconds since Unix epoch
  var hexSeconds = Math.floor(timestamp/1000).toString(16);
  // Create an ObjectId with that hex timestamp
  var constructedObjectId = ObjectId(hexSeconds + "0000000000000000");
  return constructedObjectId
}

var cursor = db['analytics.log.events'].find({
  $and: [
    {_id: {$gte: objectIdWithTimestamp(ISODate(startDate))}},
    {$or: [ {"event" : 'Started Level'}, {"event" : 'Saw Victory'}]}
    ]
});

var longestLevelName = -1;


// Copied from WorldMapView
var dungeonLevels = [
  'dungeons-of-kithgard',
  'gems-in-the-deep',
  'shadow-guard',
  'kounter-kithwise',
  'crawlways-of-kithgard',
  'forgetful-gemsmith',
  'true-names',
  'favorable-odds',
  'the-raised-sword',
  'haunted-kithmaze',
  'riddling-kithmaze',
  'descending-further',
  'the-second-kithmaze',
  'dread-door',
  'known-enemy',
  'master-of-names',
  'lowly-kithmen',
  'closing-the-distance',
  'tactical-strike',
  'the-final-kithmaze',
  'the-gauntlet',
  'kithgard-gates',
  'cavern-survival'
];

var forestLevels = [
  'defense-of-plainswood',
  'winding-trail',
  'patrol-buster',
  'endangered-burl',
  'village-guard',
  'thornbush-farm',
  'back-to-back',
  'ogre-encampment',
  'woodland-cleaver',
  'shield-rush',
  'peasant-protection',
  'munchkin-swarm',
  'munchkin-harvest',
  'swift-dagger',
  'shrapnel',
  'arcane-ally',
  'touch-of-death',
  'bonemender',
  'coinucopia',
  'copper-meadows',
  'drop-the-flag',
  'deadly-pursuit',
  'rich-forager',
  'siege-of-stonehold',
  'multiplayer-treasure-grove',
  'dueling-grounds'
];

var desertLevels = [
  'the-dunes',
  'the-mighty-sand-yak',
  'oasis',
  'sarven-road',
  'sarven-gaps',
  'thunderhooves',
  'medical-attention',
  'minesweeper',
  'sarven-sentry',
  'keeping-time',
  'hoarding-gold',
  'decoy-drill',
  'yakstraction',
  'sarven-brawl'
];

var campaigns = {
  'dungeon': dungeonLevels,
  'forest': forestLevels,
  'desert': desertLevels
};

// Bucketize events by user
print("Getting event data...");
var userProgression = {};
var userLevelEventMap = {}; // Only want unique users per-level/event
while (cursor.hasNext()) {
  var doc = cursor.next();
  var created = doc.created;
  var event = doc.event;
  if (event === 'Saw Victory') var level = doc.properties.level.toLowerCase().replace(/ /g, '-');
  else var level = doc.properties.levelID
  if (level) {
    if (level.length > longestLevelName) longestLevelName = level.length;
    var user = doc.user.valueOf();
    if (!userLevelEventMap[user]) userLevelEventMap[user] = {};
    if (!userLevelEventMap[user][level]) userLevelEventMap[user][level] = {};
    if (!userLevelEventMap[user][level][event]) {
      userLevelEventMap[user][level][event] = true;
      if (!userProgression[user]) userProgression[user] = [];
      userProgression[user].push({
        created: created,
        event: event,
        level: level
      });
    }
  }
}
longestLevelName += 2;

print("Processing data...");

// Order user progression by created
for (user in userProgression) userProgression[user].sort(function (a,b) {return a.created < b.created ? -1 : 1});

// Per-level start/drop/finish/drop
var levelProgression = {};
for (user in userProgression) {
  for (var i = 0; i < userProgression[user].length; i++) {
    var event = userProgression[user][i].event;
    var level = userProgression[user][i].level;
    if (!levelProgression[level]) {
      levelProgression[level] = {
        started: 0,
        startDropped: 0,
        finished: 0,
        finishDropped: 0
      };
    }
    if (event === 'Started Level') {
      levelProgression[level].started++;
      if (i === userProgression[user].length - 1) levelProgression[level].startDropped++;
    }
    else if (event === 'Saw Victory') {
      levelProgression[level].finished++;
      if (i === userProgression[user].length - 1) levelProgression[level].finishDropped++;
    }
  }
}


// Put in campaign order
// Calculate overall campaign stats
var campaignRates = {};
for (level in levelProgression) {
  for (campaign in campaigns) {
    if (campaigns[campaign].indexOf(level) >= 0) {
      var started = levelProgression[level].started;
      var startDropped = levelProgression[level].startDropped;
      var finished = levelProgression[level].finished;
      var finishDropped = levelProgression[level].finishDropped;
      if (!campaignRates[campaign]) {
        campaignRates[campaign] = { levels: [], overall: {
          started: 0,
          startDropped: 0,
          finished: 0,
          finishDropped: 0
        }};
      }
      campaignRates[campaign].levels.push({
        level: level,
        started: started,
        startDropped: startDropped,
        finished: finished,
        finishDropped: finishDropped
      });
      campaignRates[campaign].overall.started += started;
      campaignRates[campaign].overall.finished += finished;
      campaignRates[campaign].overall.startDropped += startDropped;
      
      // Only finishDropped if on last level in campaign
      if (campaigns[campaign].indexOf(level) === campaigns[campaign].length - 1) {
        campaignRates[campaign].overall.finishDropped += finishDropped;
      }
      else {
        campaignRates[campaign].overall.startDropped += finishDropped;
      }
      break;
    }
  }
}

// Sort level data by campaign order
for (campaign in campaignRates) {
  campaignRates[campaign].levels.sort(function(a, b) {
    if (campaigns[campaign].indexOf(a.level) < campaigns[campaign].indexOf(b.level)) return -1;
    return 1;
  });
}


print("\nCampaign drop off rates");
print("Where do players stop playing?");
print("Drop-off point: last start or finish level event.");
print("Columns: level, started the level, left after starting, finished level, left after finishing level");

for (campaign in campaigns) {
  print("\n" + campaign);
  var level = "level";
  var levelSpacer = new Array(longestLevelName - level.length).join(' ');
  print(level + levelSpacer + "started\tdropped\t\tfinished dropped\tcompletion");
  for (var i = 0; i < campaignRates[campaign].levels.length; i++) {
    var level = campaignRates[campaign].levels[i].level;
    var started = campaignRates[campaign].levels[i].started;
    var startDropped = campaignRates[campaign].levels[i].startDropped;
    var finished = campaignRates[campaign].levels[i].finished;
    var finishDropped = campaignRates[campaign].levels[i].finishDropped;
    var levelSpacer = new Array(longestLevelName - level.length).join(' ');
    print(level + levelSpacer + started + "\t" + (started < 100 ? "\t" : "") + startDropped + "\t" + (startDropped / started * 100).toFixed(2) + "%\t" + finished + "\t" + finishDropped + "\t" + (finishDropped / finished * 100).toFixed(2) + "%" + "\t" + (finished / started * 100).toFixed(2) + "%");
  }
  // var level = 'Overall';
  // var started = campaignRates[campaign].overall.started;
  // var startDropped = campaignRates[campaign].overall.startDropped;
  // var finished = campaignRates[campaign].overall.finished;
  // var finishDropped = campaignRates[campaign].overall.finishDropped;
  // var levelSpacer = new Array(longestLevelName - level.length).join(' ');
  // print(level + levelSpacer + started + "\t" + (started < 100 ? "\t" : "") + startDropped + "\t" + (startDropped / started * 100).toFixed(2) + "%\t" + finished + "\t" + finishDropped + "\t" + (finishDropped / finished * 100).toFixed(2) + "%");
}
