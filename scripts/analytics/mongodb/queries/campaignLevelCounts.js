// Print out campaign level counts

// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>

print("free premium all campaign");
var cursor = db.campaigns.find({}, {slug: 1, levels: 1});
var allFree = 0;
var allPremium = 0;
while (cursor.hasNext()) {
    var doc = cursor.next();
    if (doc.slug === 'auditions') continue;
    var free = 0;
    var premium = 0;
    for (var levelID in doc.levels) {
        if (doc.levels[levelID].requiresSubscription) {
            premium++;
        }
        else {
            free++;
        }
    }
    print(free + " " + premium + " " + (free + premium) + " " + doc.slug);

    allFree += free;
    allPremium += premium;
}
print(allFree + " " + allPremium + " " + (allFree + allPremium) + " overall");
