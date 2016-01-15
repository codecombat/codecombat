// Average level playtimes in seconds by campaign, broken up by course and campaign levels

// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>

// NOTE: faster to use find() instead of aggregate()
// NOTE: faster to ask for one level at a time.

var courseCampaigns = ['intro', 'course-2', 'course-3', 'course-4'];
var individualCampaigns = ['dungeon', 'forest', 'desert', 'mountain'];

var scriptStartTime = new Date();
var startDay = '2015-12-06';
var endDay = '2015-12-13';

print("Dates: " + startDay + " to " + endDay);

// Print out playtimes for each campaign
var campaigns = getCampaigns(courseCampaigns);

for (var i = 0; i < campaigns.length; i++) {
  var campaign = campaigns[i];
  print(campaign.slug);
  print("Sessions\tAverage\tSessions\tAverage\tLevel");
  for (var j = 0; j < campaign.levelSlugs.length; j++) {
    var levelSlug = campaign.levelSlugs[j];
    var levelPlaytimes = getPlaytimes([levelSlug]);
    if (levelPlaytimes[levelSlug]) {
      print(levelPlaytimes[levelSlug].campaign.count,
        '\t', levelPlaytimes[levelSlug].campaign.average,
        '\t', levelPlaytimes[levelSlug].course.count,
        '\t', levelPlaytimes[levelSlug].course.average,
        '\t', levelSlug);
    }
    else {
      print(0, '\t', 0, '\t', 0, '\t', 0, '\t', levelSlug);
    }
  }
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

function getCampaigns(campaignSlugs) {
  var campaigns = [];
  var cursor = db.campaigns.find({slug: {$in: campaignSlugs}}, {slug: 1, levels: 1});
  var allFree = 0;
  var allpaid = 0;
  while (cursor.hasNext()) {
    var doc = cursor.next();
    if (doc.slug === 'auditions') continue;
    var campaign = {slug: doc.slug, levelSlugs: []};
    for (var levelID in doc.levels) {
      campaign.levelSlugs.push(doc.levels[levelID].slug);
    }
    campaigns.push(campaign);
  }

  campaigns.sort(function (a, b) {
    if (campaignSlugs.indexOf(a.slug) < campaignSlugs.indexOf(b.slug)){
      return -1;
    }
    return 1;
  });
  return campaigns;
}

function getPlaytimes(levelSlugs) {
  // printjson(levelSlugs);
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
  }, {heroConfig: 1, levelID: 1, playtime: 1});

  var playtimes = {};
  while (cursor.hasNext()) {
    var myDoc = cursor.next();
    var levelID = myDoc.levelID;

    if (!playtimes[levelID]) playtimes[levelID] = {campaign: [], course: []};
    if (myDoc.heroConfig) {
      playtimes[levelID].campaign.push(myDoc.playtime);
    }
    else {
      playtimes[levelID].course.push(myDoc.playtime);
    }
  }
  // printjson(playtimes);

  var data = {};
  for (levelID in playtimes) {
    var campaignTotal = 0;
    var courseTotal = 0;
    if (playtimes[levelID].campaign.length > 0) {
      campaignTotal = playtimes[levelID].campaign.reduce(function(a, b) {return a + b;});
    }
    if (playtimes[levelID].course.length > 0) {
      courseTotal = playtimes[levelID].course.reduce(function(a, b) {return a + b;});
    }

    var campaignAverage = parseInt(playtimes[levelID].campaign.length > 0 ? parseInt(campaignTotal / playtimes[levelID].campaign.length): 0);
    var courseAverage = parseInt(playtimes[levelID].course.length > 0 ? parseInt(courseTotal / playtimes[levelID].course.length): 0);

    data[levelID] = {
      campaign: {
        count: playtimes[levelID].campaign.length,
        total: campaignTotal,
        average: campaignAverage
      },
      course: {
        count: playtimes[levelID].course.length,
        total: courseTotal,
        average: courseAverage
      }
    };
  }
  return data;
}
