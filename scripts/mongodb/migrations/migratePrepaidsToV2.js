// Update existing prepaids to v2
// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>
//
// - Add 'redeemers' property (redeemed date set to prepaid creation date)
// - Add 'maxRedeemers' property
// - Remove 'status' property
// - Remove 'redeemer' property

var host = db.getMongo().host;
if (host === 'localhost' || host === '127.0.0.1') {
  insertTestData();
}
migratePrepaidsToV2();

function migratePrepaidsToV2() {
  print("Migrating prepaids to V2...");
  var cursor = db.prepaids.find({'status': {$exists: true}});
  print("V1 prepaids found: " + cursor.count());

  while (cursor.hasNext()) {
    var doc = cursor.next();

    var conditions = {_id: doc._id};
    var operations = {
      $set: {
        maxRedeemers: NumberInt(1)
      },
      $unset: {
        status: "",
        redeemer: ""
      }
    };
    if (doc.redeemer && (!doc.redeemers || doc.redeemers.length < 1)) {
      operations.$set.redeemers = [{userID: doc.redeemer, date: doc._id.getTimestamp()}]
    }

    // printjson(conditions);
    // printjson(operations);
    var writeResult = db.prepaids.update(conditions, operations);
    // printjson(writeResult)
  }

  cursor = db.prepaids.find({'status': {$exists: true}});
  if (cursor.count()) {
    print("Error: still have prepaids with status property: " + cursor.count());
  }
  else {
    print("Done.");
  }
}

function insertTestData() {
  var host = db.getMongo().host;
  if (host !== 'localhost' && host !== '127.0.0.1') {
    print("Do NOT insert test data on a non-local mongo instance!");
    return;
  }
  for (var i = 0; i < 10; i++) {
    createPrepaid();
  }
}

// Copied from createBulkPrepaids.js and updated to V1 schema

function createPrepaid()
{
  print("Inserting prepaid:");
  generateNewCode(function(code) {
    if (!code) {
      print("ERROR: no code");
      return;
    }
    var criteria = {
      creator: ObjectId('512ef4805a67a8c507000001'),
      type: 'subscription',
      status: 'active',
      code: code,
      properties: {
        couponID: 'free'
      },
      __v: 0
    };
    if (Math.random() > 0.5) {
      criteria.redeemer = ObjectId('52f94443fcb334581466a992');
      criteria.status = 'used';
    }
    printjson(criteria);
    var writeResult = db.prepaids.insert(criteria);
    printjson(writeResult);
  });
}

function generateNewCode(done)
{
  function tryCode() {
    code = createCode(8);
    criteria = {code: code};
    if (db.prepaids.findOne(criteria)) {
      return tryCode();
    }
    return done(code);
  }
  tryCode();
}

function createCode(length)
{
    var text = "";
    var possible = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";

    for( var i=0; i < length; i++ )
        text += possible.charAt(Math.floor(Math.random() * possible.length));

    return text;
}
