// Add externally purchased subscriptions

// Usage:
// Edit hard coded data below.
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>

// Skips duplicate payments, but this might be incorrect depending on the scenario

// TODO: output emails not found

var emails = ['pam@fred.com', 'Bob@fred.com'];
var purchaserID = '';  // leave blank to use ID of user of first email address
var endDate = '';  // '2016-06-28' or blank for auto-3-months
var gems = 10500;
var amount = 2997;
var service = 'paypal';  // 'external', etc.

emails = emails.map(function(e) { return e.toLowerCase();});

if (!purchaserID) {
    var purchaser = db.users.findOne({emailLower: emails[0]});
    purchaserID = purchaser._id + '';
}

if (!endDate) {
    var date = new Date();
    var newMonth = date.getMonth() + 3;
    if (newMonth >= 12) {
        newMonth -= 12;
        date.setFullYear(date.getFullYear() + 1);
    }
    date.setMonth(newMonth);
    endDate = date.toISOString().substring(0, 10);
}

log("Input Data");
log("service\t" + service);
log("purchaserID\t" + purchaserID);
log("end date\t" + endDate);
log("gems\t" + gems);
log("amount\t" + amount);
log("emails");
log(emails);

// 1. Set free = endDate, updated purchased.gems

db.users.update(
  {emailLower: {$in: emails}, "stripe.free": {$ne: endDate}},
  {
    $set: {
      "stripe.free": endDate
    },
    $inc: {
      "purchased.gems": gems
    }
  },
  {
    multi: true
  }
);

// 2. create Payment objects

var cursor = db.users.find({emailLower: {$in: emails}});
while (cursor.hasNext()) {
  var doc = cursor.next();

  var criteria = {
    purchaser: ObjectId(purchaserID),
    recipient: doc._id,
    service: service,
    gems: gems,
    amount: amount
  }
  if (db.payments.findOne(criteria)) {
      log("Already have a payment for " + doc.email);
  }
  else {
    db.payments.insert(criteria);
    log("Added payment for " + doc.email);
  }
}

function log(str) {
  print(new Date().toISOString() + " " + str);
}
