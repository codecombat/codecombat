// Print out gem counts bucketed by day and amount


// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>
// Usage restricted to HoC Dates:
// mongo <address>:<port>/<database> -eval "var startDate='2014-12-08T00:00:00.000Z', endDate='2014-12-14T00:00:00.000Z';" <script file> -u <username> -p <password>

var match = null;

if (typeof startDate !== "undefined" && startDate !== null && typeof endDate !== "undefined" && endDate !== null) {
  print("Using dates " + startDate + " to " + endDate);
  match={
    "$match" : {
      $and : [
        {"created": { $gte: startDate}},
        {"created": { $lt: endDate}},
        {"stripe.subscriptionID" : { "$exists" : false }}
      ]
    }
  };
} else {
  print("No date range specified.");
  match={
    "$match" : {"stripe.subscriptionID" : { "$exists" : false }}
  };
}

var proj0 = {"$project": {
    "amount": 1,
    "created": { "$concat": [{"$substr" :  ["$created", 0, 4]}, "-", {"$substr" :  ["$created", 5, 2]}, "-", {"$substr" :  ["$created", 8, 2]}]}
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
var cursor = db.payments.aggregate(match, proj0, group, sort);
while (cursor.hasNext()) {
  var doc = cursor.next();
  print(doc._id.d + "\t" + doc._id.m + "\t" + doc.count);
}