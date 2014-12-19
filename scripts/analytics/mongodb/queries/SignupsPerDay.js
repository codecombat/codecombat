// Print out signup conversions per day

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
db['analytics.log.events'].aggregate(match, proj1, proj2, group, sort).result.forEach( function (myDoc) { 
//    print({day: myDoc._id.d, amount: myDoc._id.m, count: myDoc.count}) 
    if (!conversionsPerDay[myDoc._id.d])
        conversionsPerDay[myDoc._id.d] = {}
    conversionsPerDay[myDoc._id.d][myDoc._id.m] = myDoc.count;
})
for (key in conversionsPerDay) {
    print(key, conversionsPerDay[key]['Started Signup'], conversionsPerDay[key]['Finished Signup'], conversionsPerDay[key]['Finished Signup'] / conversionsPerDay[key]['Started Signup']);
//    print("Signup Conversion:", (finished / started * 100), "%");
}