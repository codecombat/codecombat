// Print out total managed subscriptions

// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>

var scriptStartTime = new Date();

var cursor = db.users.find({anonymous: false}, {stripe: 1});
var total = 0;
while (cursor.hasNext()) {
    var doc = cursor.next();
    if (doc.stripe && doc.stripe.recipients) {
        total += doc.stripe.recipients.length;
    }
}
print(total);

log("Script runtime: " + (new Date() - scriptStartTime));

function log(str) {
  print(new Date().toISOString() + " " + str);
}
