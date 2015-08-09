// Print out signup conversions since a start Date

var started = finished = 0.0
var startDate = new ISODate("2014-12-07T00:00:00.000Z")
db['analytics.log.events'].aggregate(
[ 
    { $match : 
        { $and: [
            {created : { $gte: startDate}},
            {$or: [ {"event" : 'Started Signup'}, {"event" : 'Finished Signup'}]}
        ]}
    },
    { 
        $group : { 
            _id: "$event", 
            total: {$sum: 1} 
        }
    },
    {  $sort : { total : -1} }
]
).result.forEach( function (myDoc) { 
    //print(myDoc)
    if (myDoc._id === "Started Signup")
        started += myDoc.total;
    else
        finished += myDoc.total;
})
print("Signups", started, finished);
print("Signup Conversion:", (finished / started * 100), "%");
