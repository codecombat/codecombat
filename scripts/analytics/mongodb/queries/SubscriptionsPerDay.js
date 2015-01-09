// Print out subscription counts bucketed by day and amount
// NOTE: created is a string and not an ISODate in the database

var match={
    "$match" : {
        "stripe.subscriptionID" : { "$exists" : true }
    }
};
var proj0 = {"$project": {
    "amount": 1,
    "created": {"$substr" :  ["$created", 0, 10]}
}
};
var group={"$group" : {
        "_id" : {
            "m" : "$amount",
            "d" : "$created"
        },
        "count" : {
            "$sum" : 1
        }
    }
};
var sort = {$sort: { "_id.d" : -1}};
//db.payments.aggregate(match, proj0, proj1, proj2, group)
db.payments.aggregate(match, proj0, group, sort).result.forEach( function (myDoc) { print({day: myDoc._id.d, amount: myDoc._id.m, count: myDoc.count}) })
//db.payments.aggregate(match)
//db.payments.find()