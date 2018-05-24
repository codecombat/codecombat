// For EU non-teachers who are paid or active in last 23 months, opt out of announcements/generlNews

// var euCountries = ['austria', 'belgium', 'bulgaria', 'croatia', 'cyprus', 'czech republic', 'denmark', 'estonia', 'finland', 'france', 'germany', 'greece', 'hungary', 'ireland', 'italy', 'latvia', 'lithuania', 'luxembourg', 'malta', 'netherlands', 'poland', 'portugal', 'romania', 'slovakia', 'slovenia', 'spain', 'sweden', 'united-kingdom']
const upperEUCountries = ['Austria', 'Belgium', 'Bulgaria', 'Broatia', 'Cyprus', 'Czech Republic', 'Denmark', 'Estonia', 'Finland', 'France', 'Germany', 'Greece', 'Hungary', 'Ireland', 'Italy', 'Latvia', 'Lithuania', 'Luxembourg', 'Malta', 'Netherlands', 'Poland', 'Portugal', 'Romania', 'Slovakia', 'Slovenia', 'Spain', 'Sweden', 'United-kingdom']
var teacherRoles = ['student', 'teacher', 'technology coordinator', 'advisor', 'principal', 'superintendent', 'parent'];

// var newestDate = ISODate();
// newestDate.setUTCMonth(newestDate.getUTCMonth() - 23);
var newestDate = ISODate("2016-06-24");
// print(newestDate.tojson());
// var newestStr = newestDate.tojson();

var query = {$and: [
    {$or: [
        // Active recently
        {$or: [
            {$and: [
                {'activity.login.last': {$exists: true}}, {'activity.login.last': {$gte: newestDate}}
            ]}, 
            {$and: [
                {'activity.login.last': {$exists: false}}, {dateCreated: {$gte: newestDate}}
            ]}
        ]},
        // Or a paid user
        {$or: [{'stripe.subscriptionID': {$exists: true}}, {'stripe.sponsorID': {$exists: true}}]}
    ]},
    // EU user
    // NOTE: this country detection was used on 5/24/18 to incorrectly opt-out users outside EU
    // {$or: [{country: {$in: euCountries}}, {country: {$exists: false}}]},
    {$or: [
        {country: {$in: upperEUCountries}},
        {'geo.countryName': {$in: upperEUCountries}},
        // TODO: only removing this temporarily to fix previous country case matching issue
        // {$and: [{country: {$exists: false}}, {'geo.countryName': {$exists: false}}]},
    ]},
    // Not a teacher
    {role: {$nin: teacherRoles}},
    {anonymous: false}
]};

// For testing
// db.users.find(query, {emailLower: 1, country: 1, 'activity.login.last': 1, dateCreated: 1, stripe: 1}).limit(2).toArray().forEach(function(user) {
//     printjson(user);
// });
// 

db.users.update(
    query,
    {$set: {
        "emails.generalNews.enabled": false
        }
    },
   {multi: true}
)
