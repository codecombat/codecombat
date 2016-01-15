// Add 2 course headcount to older approved teacher surveys

// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>

// Who needs 2 course headcount added?
// Approved trial.requests but no prepaid with properties.trialRequestID set

// Priority userID selection
// 1. UserID that redeemed approved prepaid
// 2. UserID that applied for trial request
// 3. User email that applied for trial request
// NOTE: May give course headcount to multiple accounts if they applied and redeemed with different users

addHeadcount();

function addHeadcount() {
  print("Finding approved trial requests..");

  var approvedUserIDMap = {};
  var approvedUserEmails = [];
  var codeRequestMap = {};
  var userIDRequestMap = {};
  var userEmailRequestMap = {};
  var cursor = db['trial.requests'].find({status: 'approved', type: 'subscription'}, {});
  while (cursor.hasNext()) {
    var doc = cursor.next();
    if (doc.applicant) {
      approvedUserIDMap[doc.applicant.valueOf()] = false;
      userIDRequestMap[doc.applicant.valueOf()] = doc._id;
    }
    if (doc.prepaidCode) {
      codeRequestMap[doc.prepaidCode] = doc._id;
    }
    approvedUserEmails.push(doc.properties.email.toLowerCase());
    userEmailRequestMap[doc.properties.email.toLowerCase()] = doc._id;
  }

  print("Finding users via redeemed prepaids..");
  cursor = db.prepaids.find({code: {$in: Object.keys(codeRequestMap)}});
  while (cursor.hasNext()) {
    var doc = cursor.next();
    if (doc.redeemers && doc.redeemers.length > 0) {
      for (var i = 0; i < doc.redeemers.length; i++) {
        approvedUserIDMap[doc.redeemers[i].userID.valueOf()] = false;
        userIDRequestMap[doc.redeemers[i].userID.valueOf()] = codeRequestMap[doc.code];
      }
    }
  }

  print("Finding users via approved emails..");
  cursor = db.users.find({emailLower: {$in: approvedUserEmails}});
  while (cursor.hasNext()) {
    var doc = cursor.next();
    approvedUserIDMap[doc._id.valueOf()] = false;
    if (userEmailRequestMap[doc.emailLower]) {
      // Trial request had a known email, but not an applicant field set
      userIDRequestMap[doc._id.valueOf()] = userEmailRequestMap[doc.emailLower];
    }
  }

  var approvedUserIDs = [];
  for (var userID in approvedUserIDMap) {
    approvedUserIDs.push(new ObjectId(userID));
  }
  print("Approved user IDs:", approvedUserIDs.length);

  print("Finding approved users with trial request headcount..");
  cursor = db.prepaids.find({$and: [{creator: {$in: approvedUserIDs}}, {'properties.trialRequestID': {$exists: true}}]});
  while (cursor.hasNext()) {
    var doc = cursor.next();
    approvedUserIDMap[doc.creator.valueOf()] = true;
  }

  var needsHeadcount = [];
  for (var userID in approvedUserIDMap) {
    if (approvedUserIDMap[userID] === false) {
      needsHeadcount.push(ObjectId(userID));
    }
  }
  print("Needs headcount:", needsHeadcount.length);

  var updateCount = 0;
  function insertHeadCount(userID) {
    if (!userIDRequestMap[userID.valueOf()]) {
      print('ERROR: No trial request ID', userID);
      print('Trial course headcount prepaids inserted:', updateCount);
      return;
    }

    generateNewCode(function(code) {
      if (!code) {
        print("ERROR: no code");
        return;
      }
      criteria = {
        creator: userID,
        type: 'course',
        maxRedeemers: NumberInt(2),
        properties: {
          trialRequestID: userIDRequestMap[userID.valueOf()]
        },
        exhausted: false,
        __v: NumberInt(0)
      };
      if (!db.prepaids.findOne(criteria)) {
        // print('Adding trial request prepaid for', userID, code);
        criteria.code = code;
        var writeResult = db.prepaids.insert(criteria);
        updateCount += writeResult.nInserted;
      }
      else {
        print('ERROR: Already has trial request headcount', userID, criteria.properties.trialRequestID);
        print('Trial course headcount prepaids inserted:', updateCount);
        return;
      }

      if (updateCount < 500 && needsHeadcount.length > 0) {
        insertHeadCount(needsHeadcount.pop());
      }
      else {
        print('Trial course headcount prepaids inserted:', updateCount);
      }
    });
  }

  if (needsHeadcount.length > 0) {
    insertHeadCount(needsHeadcount.pop());
  }
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
    var possible = "abcdefghijklmnopqrstuvwxyz0123456789";

    for( var i=0; i < length; i++ ) {
      text += possible.charAt(Math.floor(Math.random() * possible.length));
    }

    return text;
}
