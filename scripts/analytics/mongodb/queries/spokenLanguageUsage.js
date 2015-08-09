// Print out spoken language usage based on signed-in user data

// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>

var total = 0;
var languages = {};
//var startDate = new ISODate("2014-12-01T00:00:00.000Z");
var cursor = db['users'].aggregate(
[ 
    { $match : {
        //$and: [{codeLanguage: {$exists: true}}, {created : { $gte: startDate}}]
        anonymous: false
    }
    },
    { 
        $group : { 
            _id: "$preferredLanguage", 
            total: {$sum: 1} 
        }
    },
    {  $sort : { total : -1} }
]);

while (cursor.hasNext()) {
  var myDoc = cursor.next();
  total += myDoc.total;
  var lang = myDoc._id || 'en-US';
  if (!languages[myDoc._id])
      languages[myDoc._id] = 0
  languages[myDoc._id] += myDoc.total
}
print("Total registered users with spoken languages", total);
for (key in languages) {
    print(languages[key] + "\t" + (languages[key] / total * 100).toFixed(2) + "%\t" + key);
}
