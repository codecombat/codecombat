// Print out event totals

// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>

var cursor = db['analytics.log.events'].aggregate(
[ 
    { $match : {}},
    { 
        $group : { 
            _id: "$event", 
            total: {$sum: 1} 
        }
    },
    {  $sort : { total : -1} }
]);

while (cursor.hasNext()) {
  var myDoc = cursor.next();
  print(myDoc.total + "\t" + myDoc._id)
}
