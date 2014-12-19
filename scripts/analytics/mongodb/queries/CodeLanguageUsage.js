// Print out code language usage based on level session data
var total = 0;
var languages = {};
var startDate = new ISODate("2014-12-01T00:00:00.000Z")
db['level.sessions'].aggregate(
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
]
).result.forEach( function (myDoc) { 
    //print(myDoc)
    total += myDoc.total;
    if (!languages[myDoc._id])
        languages[myDoc._id] = 0
    languages[myDoc._id] += myDoc.total
})
print("Total sessions with code languages", total);
for (key in languages) {
    print(key, languages[key], languages[key] / total * 100);
}