// Parent emails sent and converted

// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>

// TODO: Count emails to self differently?

var scriptStartTime = new Date();
try {

  var emailTypes = ["subscribe modal parent", "share progress modal parent", "share progress modal friend"];

  // var cursor = db.users.find({$and: [{'stripe': {$exists: true}}, {'emails.oneTimes': {$exists: true}}]});
  var cursor = db.users.find({$and: [{'emails.oneTimes': {$exists: true}}]});

  var sent = {};
  var converted = {};
  while (cursor.hasNext()) {
    var doc = cursor.next();
    var created = doc._id.getTimestamp().toISOString();
    var emailOneTimes = doc.emails.oneTimes;

    for (var i = 0; i < doc.emails.oneTimes.length; i++) {
      var oneTime = doc.emails.oneTimes[i];
      if (emailTypes.indexOf(oneTime.type) >= 0) {
        if (!sent[oneTime.type]) sent[oneTime.type] = {};
        sent[oneTime.type][doc._id.valueOf()] = true;

        var payment = db.payments.findOne({recipient: doc._id});
        if (payment) {
          var paymentCreated = payment._id.getTimestamp().toISOString();
          var emailCreated = doc._id.getTimestamp().toISOString();
          // If email created before payment received
          if (emailCreated.localeCompare(paymentCreated) < 0) {
            if (!converted[oneTime.type]) converted[oneTime.type] = {};
            converted[oneTime.type][doc._id.valueOf()] = true;
          }
        }

        break;
      }
    }
  }

  // printjson(sent);
  // printjson(converted);

  var stats = {};

  for (var type in sent) {
    if (!stats[type]) stats[type] = {};
    stats[type].sent = Object.keys(sent[type]).length;
  }
  for (var type in converted) {
    stats[type].converted = Object.keys(converted[type]).length;
    stats[type].rate = (stats[type].converted / stats[type].sent * 100).toFixed(2);
  }

  log("Sent\tConverted\tRate\tType");
  for (var type in stats) {
    log(stats[type].sent + "\t" + stats[type].converted + "\t" + stats[type].rate + "\t" + type);
  }
}
catch(err) {
  log("ERROR: " + err);
  printjson(err);
}
finally {
  log("Script runtime: " + (new Date() - scriptStartTime));
}

// *** Helper functions ***

function log(str) {
  print(new Date().toISOString() + " " + str);
}

function objectIdWithTimestamp(timestamp) {
  // Convert string date to Date object (otherwise assume timestamp is a date)
  if (typeof(timestamp) == 'string') timestamp = new Date(timestamp);
  // Convert date object to hex seconds since Unix epoch
  var hexSeconds = Math.floor(timestamp/1000).toString(16);
  // Create an ObjectId with that hex timestamp
  var constructedObjectId = ObjectId(hexSeconds + "0000000000000000");
  return constructedObjectId
}
