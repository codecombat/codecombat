// Print out code language usage based on level session data

// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>

var total = 0;
var languages = {};
var startDate = new ISODate("2014-12-01T00:00:00.000Z")
var cursor = db['level.sessions'].aggregate(
[ 
    { $match : {
        //$and: [{codeLanguage: {$exists: true}}, {created : { $gte: startDate}}]
        codeLanguage: {$exists: true}
    }
    },
    { 
        $group : { 
            _id: "$codeLanguage", 
            total: {$sum: 1} 
        }
    },
    {  $sort : { total : -1} }
]);

while (cursor.hasNext()) {
  var myDoc = cursor.next();
  total += myDoc.total;
  if (!languages[myDoc._id])
      languages[myDoc._id] = 0
  languages[myDoc._id] += myDoc.total
}
print("Total sessions with code languages", total);
for (key in languages) {
    print(key + "\t" + languages[key] + "\t" + (languages[key] / total * 100).toFixed(2) + "%");
}