// Find completed level counts immediately after subscription purchase

// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>
// Usage restricted to HoC Dates:
// mongo <address>:<port>/<database> -eval "var startDate='2014-12-08T00:00:00.000Z', endDate='2014-12-14T00:00:00.000Z';" <script file> -u <username> -p <password>

// TODO: This is nearly identical to LevelPlayedBeforeSub.js

var nextLevelPlayedCompleted = {};
var paymentsCursor;

if (typeof startDate !== "undefined" && startDate !== null && typeof endDate !== "undefined" && endDate !== null) {
  print("Using dates " + startDate + " to " + endDate);
  paymentsCursor = db.payments.find({ 
    $and: [
    {"created": { $gte: startDate}},
    {"created": { $lt: endDate}},
    {"stripe.subscriptionID" : { "$exists" : true }}
    ]
  });  
} else {
  print("No date range specified.");
  paymentsCursor = db.payments.find({"stripe.subscriptionID" : { "$exists" : true }});    
}

while (paymentsCursor.hasNext()) {
    var doc = paymentsCursor.next();
    var ID = doc._id;
    var purchaseDate = doc.created;

    // Find next level session completed
    var levelSessionCursor = db['level.sessions'].find({
        $and: [{"state.complete" : true}, {creator : doc.purchaser.valueOf()}, {created: {$gt: ISODate(purchaseDate)}}]
    }).sort({created: 1});

    if (levelSessionCursor.hasNext()) {
        var nextLevelSession = levelSessionCursor.next();

        // Find last level completed
        var levelCursor = db.levels.find({"original" : ObjectId(nextLevelSession.level.original), "version.isLatestMajor": true, "version.isLatestMinor": true})
        if (levelCursor.hasNext()) {
            var nextLevel = levelCursor.next();
            if (!nextLevelPlayedCompleted[nextLevel.name])
                nextLevelPlayedCompleted[nextLevel.name] = 0;
            nextLevelPlayedCompleted[nextLevel.name]++;
        }
        else {
            if (!nextLevelPlayedCompleted['unknown'])
                nextLevelPlayedCompleted['unknown'] = 0;
            nextLevelPlayedCompleted['unknown']++;
        }
    }
    else {
        if (!nextLevelPlayedCompleted['unknown'])
            nextLevelPlayedCompleted['unknown'] = 0;
        nextLevelPlayedCompleted['unknown']++;
    }
}

// Sort descending count and print
var sorted = [];
for (key in nextLevelPlayedCompleted) {
    sorted.push({name: key, count: nextLevelPlayedCompleted[key]});
}
sorted.sort(function(a,b) { return b.count - a.count});
for (var i = 0; i < sorted.length; i++) {
    print(sorted[i].count + "\t" + sorted[i].name);
}
