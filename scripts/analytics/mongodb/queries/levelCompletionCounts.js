// Level completion counts broken down into free and paid buckets

// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>

// TODO: subscriber is someone who is currently subscribed, not necessarily subscribed when they completed a level

// Excluded for one reason or another
// Some relevant code:  https://github.com/codecombat/codecombat/blob/master/app/views/play/CampaignView.coffee#L281-L292
var excludedLevels = ['deadly-dungeon-rescue', 'kithgard-brawl', 'cavern-survival', 'kithgard-mastery', 'destroying-angel', 'kithgard-apprentice', 'wild-horses', 'lost-viking', 'forest-flower-grove', 'boulder-woods', 'the-trials'];

var scriptStartTime = new Date();
var startDay = '2015-05-16';
var endDay = '2015-06-17';

log("Dates: " + startDay + " to " + endDay);

var subscribers = getSubscribers();
log("Subscriber count: " + Object.keys(subscribers).length);

var campaigns = getCampaigns();
for (var i = 0; i < campaigns.length; i++) {
  var campaign = campaigns[i];
  // if (campaign.slug !== 'mountain') continue;

  function printCampaign(title, prop) {
    print(title)
    print("Total\tFree\tSubscribers");
    for (var j = 0; j < campaign[prop].length; j++) {
      var levelSlug = campaign[prop][j];
      if (excludedLevels.indexOf(levelSlug) >= 0) continue;
      var data = getCompletionCounts([levelSlug], subscribers);
      if (data[levelSlug]) {
        var free = data[levelSlug].free.length;
        var paid = data[levelSlug].paid.length;
        var total = free + paid;
        var paidRate = parseInt(paid / total * 100);
        print(total + "\t" + free + "\t" + paid + "\t\t" + paidRate + "%\t" + levelSlug);
      }
      else {
        print("0\t0\t0\t\t0%\t" + levelSlug);
      }
    }
  }

  printCampaign(campaign.slug + " (free)", "free");
  printCampaign(campaign.slug + " (paid)", "paid");
  printCampaign(campaign.slug + " (replayable)", "replayable");

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

function getCompletionCounts(levelSlugs, subscribers) {
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
  });

  var completionCounts = {};
  while (cursor.hasNext()) {
    var myDoc = cursor.next();
    var userID = myDoc.creator;
    var levelID = myDoc.levelID;

    if (!completionCounts[levelID]) completionCounts[levelID] = {free: [], paid: []};
    if (subscribers[userID]) {
      completionCounts[levelID].paid.push(myDoc._id.valueOf());
    }
    else {
      completionCounts[levelID].free.push(myDoc._id.valueOf());
    }
  }

  return completionCounts;
}

function getSubscribers() {
  var cursor = db['users'].find({
    $and:
    [
      {
        $or:
        [
          {"stripe.sponsorID": {$exists: true}},
          {$and:
            [
              {"stripe.subscriptionID": {$exists: true}},
              {"stripe.planID": 'basic'}
            ]
          }
        ]
      },
      {permissions: {$ne: ['admin']}},
      {"stripe.free": {$exists: false}},
      {"stripe.coupon": {$exists: false}},
      {"stripe.prepaidCode": {$exists: false}}
    ]
  });

  var subscribers = {};
  while (cursor.hasNext()) {
    subscribers[cursor.next()._id.valueOf()] = true;
  }
  return subscribers;
}
