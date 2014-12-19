// Find completed level counts immediately before subscription purchase

// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>
// Usage restricted to HoC Dates:
// mongo <address>:<port>/<database> -eval "var startDate='2014-12-08T00:00:00.000Z', endDate='2014-12-14T00:00:00.000Z';" <script file> -u <username> -p <password>

// TODO: Must be a better way to query for this data all at once.

var lastLevelCompleted = {};
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
    
    // Find last level session completed
    var levelSessionCursor = db['level.sessions'].find({
        $and: [{"state.complete" : true}, {creator : doc.purchaser.valueOf()}, {changed: {$lt: ISODate(purchaseDate)}}]
    }).sort({created: -1});
    if (levelSessionCursor.hasNext()) {
        var lastLevelSessionCompleted = levelSessionCursor.next();
        
        // Find last level completed
        var levelCursor = db.levels.find({"original" : ObjectId(lastLevelSessionCompleted.level.original), "version.isLatestMajor": true, "version.isLatestMinor": true})
        if (levelCursor.hasNext()) {
            var lastLevel = levelCursor.next();
            if (!lastLevelCompleted[lastLevel.name])
                lastLevelCompleted[lastLevel.name] = 0;
            lastLevelCompleted[lastLevel.name]++;
        }
        else {
            if (!lastLevelCompleted['unknown'])
                lastLevelCompleted['unknown'] = 0;
            lastLevelCompleted['unknown']++;
        }
    }
    else {
        if (!lastLevelCompleted['unknown'])
            lastLevelCompleted['unknown'] = 0;
        lastLevelCompleted['unknown']++;
    }
}

// Sort descending count and print
var sorted = [];
for (key in lastLevelCompleted) {
    sorted.push({name: key, count: lastLevelCompleted[key]});
}
sorted.sort(function(a,b) { return b.count - a.count});
for (var i = 0; i < sorted.length; i++) {
    print(sorted[i].count + "\t" + sorted[i].name);
}
