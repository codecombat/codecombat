// Aggregate start/finish level event counts by day using mapReduce

// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>

// TODO: This basically never returns.  Why so slow?
// TODO: For only endangered-burl and dungeons-of-kithgard on 1/7/15
// TODO: 20s removing uniques in reduce, 7.6s keeping uniques, 9s removing uniques in finalize
// TODO: For all levels on 1/7/15, 136s.  Yikes!
// Calling mapReduce...
// {
//   "mapTime" : 4924,
//   "emitLoop" : 134561,
//   "reduceTime" : 128327,
//   "mode" : "mixed",
//   "total" : 136173
// }
// { "input" : 98194, "emit" : 98194, "reduce" : 27074, "output" : 202 }



function map() {
    var user = this.user;
    var event = this.event;
    var level;
    if (this.properties['level']) {
        level = this.properties['level'].toLowerCase().replace(/ /g, '-');
        event = 'finished';
    }
    else if (this.properties['levelID']) {
        level = this.properties['levelID'];
        event = 'started';
    }
    else {
      return;
    }
    var created = this.created.toISOString().substring(0, 10);
    // Have to wrap array value in an object
    // http://stackoverflow.com/questions/8175015/mongodb-mapreduce-reduce-multiple-not-supported-yet
    emit({"event": event, "level": level, "created": created}, {users: [user]});
}

function reduce(key, values) {
    // Combine individual user lists
    // values: [{users: [user1, user2]}, {users: [user1, user3]}, ...]
    var set = [];
    for (var i = 0; i < values.length; i++) set = set.concat(values[i].users);
    return {users: set};
}
function finalize(key, reducedVal) {
    // Convert to unique user count
    var users = {};
    for (var i = 0; i < reducedVal.users.length; i++) users[reducedVal.users[i]] = true;
    return Object.keys(users).length;
}

print("Calling mapReduce...");
var output = db['analytics.log.events'].mapReduce(map, reduce,
{
    query: {
      $and: [
        {created: {$gte: ISODate("2015-01-07T00:00:00.000Z")}},
        {created: {$lt: ISODate("2015-01-08T00:00:00.000Z")}},
//        {$or: [ {"properties.level": {$exists: true}}, {"properties.levelID": {$exists: true}}]},
        // {$or: [ 
        // {"properties.level": "Endangered Burl"}, {"properties.levelID": "endangered-burl"},
        // {"properties.level": "Dungeons of Kithgard"}, {"properties.levelID": "dungeons-of-kithgard"}
        // ]},
        {$or: [ {"event" : 'Started Level'}, {"event" : 'Saw Victory'}]}
      ]
    },
    finalize: finalize,
    out: { inline: 1 },
    verbose: true
});

var results = output.results;
// print(results.length);
printjson(output.timing);
printjson(output.counts);
print("Printing results...");
for (var i = 0; i < results.length; i++) {
// //    if (results[i]["_id"]["level"] === "endangered-burl")
// //        print(results[i]["_id"]["created"], results[i]["_id"]["event"], results[i]["value"]);
    print(results[i]["_id"]["created"], results[i]["_id"]["event"], results[i]["value"], results[i]["_id"]["level"]);
//     printjson(results[i]);
}