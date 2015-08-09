// Average level playtimes by campaign

// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>

// NOTE: faster to use find() instead of aggregate()
// NOTE: faster to ask for one level at a time.  also keeps levels in campaign order

// Excluded for one reason or another
// Some relevant code:  https://github.com/codecombat/codecombat/blob/master/app/views/play/CampaignView.coffee#L281-L292
var excludedLevels = ['deadly-dungeon-rescue', 'kithgard-brawl', 'cavern-survival', 'kithgard-mastery', 'destroying-angel', 'kithgard-apprentice', 'wild-horses', 'lost-viking', 'forest-flower-grove', 'boulder-woods', 'the-trials'];

var scriptStartTime = new Date();
var startDay = '2015-07-01';
var endDay = '2015-08-06';

log("Dates: " + startDay + " to " + endDay);

// Print out playtimes for each campaign
var campaigns = getCampaigns();
for (var i = 0; i < campaigns.length; i++) {
  var campaign = campaigns[i];
  // if (campaign.slug !== 'dungeon') continue;
  print(campaign.slug + " (free)");
  var total = 0;

  for (var j = 0; j < campaign.free.length; j++) {
    var levelSlug = campaign.free[j];
    if (excludedLevels.indexOf(levelSlug) >= 0) continue;
    var data = getPlaytimes([levelSlug]);
    print(data[levelSlug].average + "\t" + data[levelSlug].count + "\t" + levelSlug);
    total += data[levelSlug];
  }
  // print(parseInt(total/60/60) + "\t\t total hours");
  total = 0;

  print(campaign.slug + " (paid)");
  for (var j = 0; j < campaign.paid.length; j++) {
    var levelSlug = campaign.paid[j];
    if (excludedLevels.indexOf(levelSlug) >= 0) continue;
    var data = getPlaytimes([levelSlug]);
    if (data[levelSlug]) {
      print(data[levelSlug].average + "\t" + data[levelSlug].count + "\t" + levelSlug);
      total += data[levelSlug];
    }
    else {
      print("0\t0\t" + levelSlug);
    }
  }
  // print(parseInt(total/60/60) + "\t\t total hours");
  total = 0;

  print(campaign.slug + " (replayable)");
  for (var j = 0; j < campaign.replayable.length; j++) {
    var levelSlug = campaign.replayable[j];
    if (excludedLevels.indexOf(levelSlug) >= 0) continue;
    var data = getPlaytimes([levelSlug]);
    print(data[levelSlug].average + "\t" + data[levelSlug].count + "\t" + levelSlug);
    total += data[levelSlug];
  }
  // print(parseInt(total/60/60) + "\t\t total hours");

  // break;
}

log("Script runtime: " + (new Date() - scriptStartTime));

function log(str) {
  print(new Date().toISOString() + " " + str);
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

function getCampaigns() {
  var campaigns = [];
  var cursor = db.campaigns.find({}, {slug: 1, levels: 1});
  var allFree = 0;
  var allpaid = 0;
  while (cursor.hasNext()) {
    var doc = cursor.next();
    if (doc.slug === 'auditions') continue;
    var campaign = {slug: doc.slug, free: [], paid: [], replayable: []};
    for (var levelID in doc.levels) {
      if (doc.levels[levelID].replayable) {
        campaign.replayable.push(doc.levels[levelID].slug);
      }
      else if (doc.levels[levelID].requiresSubscription) {
        campaign.paid.push(doc.levels[levelID].slug);
      }
      else {
        campaign.free.push(doc.levels[levelID].slug);
      }
    }
    campaigns.push(campaign);
  }
  return campaigns;
}

function getPlaytimes(levelSlugs) {
  var startObj = objectIdWithTimestamp(ISODate(startDay + "T00:00:00.000Z"));
  var endObj = objectIdWithTimestamp(ISODate(endDay + "T00:00:00.000Z"))
  var cursor = db['level.sessions'].find({
    $and:
    [
      {"state.complete": true},
      {"playtime": {$gt: 0}},
      {levelID: {$in: levelSlugs}},
      {_id: {$gte: startObj}},
      {_id: {$lt: endObj}}
    ]
  });

  var playtimes = {};
  while (cursor.hasNext()) {
    var myDoc = cursor.next();
    var levelID = myDoc.levelID;
    if (!playtimes[levelID]) playtimes[levelID] = [];
    playtimes[levelID].push(myDoc.playtime);
  }

  var data = {};
  for (levelID in playtimes) {
    var total = playtimes[levelID].reduce(function(a, b) {return a + b;});
    data[levelID] = {count: playtimes[levelID].length, total: total};
    data[levelID]['average'] = parseInt(total / playtimes[levelID].length);
  }
  return data;
}
