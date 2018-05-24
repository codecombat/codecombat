// For EU non-teachers who are paid or active in last 23 months, opt out of announcements/generlNews

var euCountries = ['austria', 'belgium', 'bulgaria', 'croatia', 'cyprus', 'czech republic', 'denmark', 'estonia', 'finland', 'france', 'germany', 'greece', 'hungary', 'ireland', 'italy', 'latvia', 'lithuania', 'luxembourg', 'malta', 'netherlands', 'poland', 'portugal', 'romania', 'slovakia', 'slovenia', 'spain', 'sweden', 'united-kingdom']
var teacherRoles = ['student', 'teacher', 'technology coordinator', 'advisor', 'principal', 'superintendent', 'parent'];

var newestDate = ISODate();
newestDate.setUTCMonth(newestDate.getUTCMonth() - 23);
var newestStr = newestDate.toISOString();

var query = {$and: [
    {$or: [
        // Active recently
        {$or: [
            {$and: [
                {'activity.login.last': {$exists: true}}, {'activity.login.last': {$gte: newestStr}}
            ]}, 
            {$and: [
                {'activity.login.last': {$exists: false}}, {dateCreated: {$gte: newestDate}}
            ]}
        ]},
        // Or a paid user
        {$or: [{'stripe.subscriptionID': {$exists: true}}, {'stripe.sponsorID': {$exists: true}}]}
    ]},
    // EU user
    {$or: [{country: {$in: euCountries}}, {country: {$exists: false}}]},
    // Not a teacher
    {role: {$nin: teacherRoles}},
    {anonymous: false}
]};

// For testing
// var users = db.users.find(query, {emailLower: 1, country: 1, 'activity.login.last': 1, dateCreated: 1, stripe: 1}).toArray();
// for (var i = 0; i < users.length; i++) {
//     printjson(users[i]);
// }

db.users.update(
    query,
    {$set: {
        "emails.generalNews.enabled": false
        }
    },
    {multi: true}
)
