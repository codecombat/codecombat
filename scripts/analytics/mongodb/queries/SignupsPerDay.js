// Print out signup conversions per day

// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>

// TODO: Dec 18th has more signups finished than started. Too good to be true.

var match={
    "$match" : {
        $or: [ {"event" : 'Started Signup'}, {"event" : 'Finished Signup'}]
    }
};

proj1={"$project" : {
        "_id" : 0,
        "created" : 1,
        "event" : 1,
        "h" : {
            "$hour" : "$created"
        },
        "m" : {
            "$minute" : "$created"
        },
        "s" : {
            "$second" : "$created"
        },
        "ml" : {
            "$millisecond" : "$created"
        }
    }
};

var proj2={"$project" : {
        "_id" : 0,
        "event" : 1,
        "created" : {
            "$subtract" : [
                "$created",
                {
                    "$add" : [
                        "$ml",
                        {
                            "$multiply" : [
                                "$s",
                                1000
                            ]
                        },
                        {
                            "$multiply" : [
                                "$m",
                                60,
                                1000
                            ]
                        },
                        {
                            "$multiply" : [
                                "$h",
                                60,
                                60,
                                1000
                            ]
                        }
                    ]
                }
            ]
        }
    }
};
var group={"$group" : {
        "_id" : {
            "m" : "$event",
            "d" : "$created"
        },
        "count" : {
            "$sum" : 1
        }
    }
};
var conversionsPerDay = {};
var sort = {$sort: { "_id.d" : -1}};
var cursor = db['analytics.log.events'].aggregate(match, proj1, proj2, group, sort);

while (cursor.hasNext()) {
  var myDoc = cursor.next();
  var key = myDoc._id.d.toDateString()
  if (!conversionsPerDay[key]) conversionsPerDay[key] = {}
  conversionsPerDay[key][myDoc._id.m] = myDoc.count;
}
for (key in conversionsPerDay) {
    print(key + "\t" + conversionsPerDay[key]['Started Signup'] + "\t" + conversionsPerDay[key]['Finished Signup'] + "\t" + (conversionsPerDay[key]['Finished Signup'] / conversionsPerDay[key]['Started Signup'] * 100).toFixed(2) + "%");
}