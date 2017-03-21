// Campaign completion counts

// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>

var courseCampaigns = ['intro', 'course-2', 'course-3', 'course-4'];
var individualCampaigns = ['dungeon', 'forest', 'desert', 'mountain'];

var scriptStartTime = new Date();
var startDay = '2015-11-08';
var endDay = '2015-11-15';  // Not inclusive

log("Dates: " + startDay + " to " + endDay);

var campaigns = getCampaigns(courseCampaigns);
// var campaigns = getCampaigns(individualCampaigns);
// printjson(campaigns);

for (var i = 0; i < campaigns.length; i++) {
  var campaign = campaigns[i];
  print(campaign.slug);
  print("Total\tCampaign\tCourse\tLevel");
  var completionCounts = getCompletionCounts(campaign.levelSlugs);
  for (var j = 0; j < campaign.levelSlugs.length; j++) {
    var levelSlug = campaign.levelSlugs[j];
    if (completionCounts[levelSlug]) {
      print(completionCounts[levelSlug].campaign + completionCounts[levelSlug].course,
        '\t', completionCounts[levelSlug].campaign,
        '\t', completionCounts[levelSlug].course,
        '\t', levelSlug);
    }
    else {
      print(0, '\t', 0, '\t', 0, '\t', levelSlug);
    }
  }
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

function getCompletionCounts(levelSlugs) {
  var startObj = objectIdWithTimestamp(ISODate(startDay + "T00:00:00.000Z"));
  var endObj = objectIdWithTimestamp(ISODate(endDay + "T00:00:00.000Z"))
  var cursor = db['level.sessions'].find({
    $and:
    [
      {"state.complete": true},
      {levelID: {$in: levelSlugs}},
      {_id: {$gte: startObj}},
      {_id: {$lt: endObj}}
    ]
  }, {heroConfig: 1, levelID: 1});

  var completionCounts = {};
  while (cursor.hasNext()) {
    var myDoc = cursor.next();
    var levelID = myDoc.levelID;

    if (!completionCounts[levelID]) completionCounts[levelID] = {campaign: 0, course: 0};
    if (myDoc.heroConfig) {
      completionCounts[levelID].campaign++;
    }
    else {
      completionCounts[levelID].course++;
    }
  }

  return completionCounts;
}
