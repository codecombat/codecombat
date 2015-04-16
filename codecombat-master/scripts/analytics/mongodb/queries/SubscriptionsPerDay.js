// Print out subscription counts bucketed by day and amount
// NOTE: created is a string and not an ISODate in the database

// Usage:
// mongo <address>:<port>/coco <script file> -u <username> -p <password>

// TODO: does not differeniate between new and recurring payments

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
var cursor = db.payments.aggregate(match, proj0, group, sort);
while (cursor.hasNext()) {
  var myDoc = cursor.next();
  print(myDoc._id.d, myDoc._id.m, myDoc.count);
}
//db.payments.aggregate(match, proj0, group, sort)
//db.payments.aggregate(match)
//db.payments.find()
