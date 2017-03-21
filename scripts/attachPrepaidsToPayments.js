/* global process */
// Attach missing prepaidID properties to Payments

// TODO: investigate payments that match multiple prepaids
// TODO: investigate payments that don't match any prepaids

// Payments and Stripe charges are tightly bound via payment.stripe.chargeID
// Stripe charges and prepaids are loosely bound via maxRedeemers, type, and user

// Steps:
// 1. Find paid prepaids for courses and subscriptions
// 2. Find paid prepaids disconnected from payments
// 3. Find Stripe charge payments for disconnected prepaid users
// 4. Set payment.prepaidID for charges matching prepaids

if (process.argv.length !== 4) {
  log("Usage: node <script> <Stripe API key> <mongo connection Url>");
  process.exit();
}

var scriptStartTime = new Date();
var stripeAPIKey = process.argv[2];
var mongoConnUrl = process.argv[3];
var stripe = require("stripe")(stripeAPIKey);
var MongoClient = require('mongodb').MongoClient;
var ObjectId = require('mongodb').ObjectId;

MongoClient.connect(mongoConnUrl, function (err, db) {
  if (err) {
    console.log(err);
    return;
  }
  // Find paid prepaids for courses and subscriptions
  var prepaidTypes = ['course', 'terminal_subscription'];
  getPaidPrepaids(db, prepaidTypes, function(prepaidIDs, prepaidPaymentMap, userPrepaidsMap) {
    log("Paid prepaids: " + prepaidIDs.length);

    // Find paid prepaids disconnected from payments
    getDisconnectedPrepaidUsers(db, prepaidIDs, prepaidPaymentMap, function(missingUserIDs) {
      log("Prepaids with no payment: " + missingUserIDs.length);

      // Find Stripe charge payments for disconnected prepaid users
      getDisconnectedCharges(db, missingUserIDs, function(chargePaymentMap, disconnectedCharges) {
        log("Disconnected charges: " + disconnectedCharges.length);

        // Set payment.prepaidID for charges matching prepaids 
        attachPrepaidsToPayments(db, chargePaymentMap, disconnectedCharges, userPrepaidsMap, function() {
          db.close();
          log("Script runtime: " + (new Date() - scriptStartTime));
        });
      });
    });
  });
});

function getPaidPrepaids(db, prepaidTypes, done) {
  db.collection('prepaids').find({type: {$in: prepaidTypes}}, {creator: 1, maxRedeemers: 1, properties: 1, type: 1}).toArray(function(err, prepaids) {
    if (err) {
      console.log(err);
      return done([], {}, {});
    }
    var prepaidIDs = [];
    var prepaidPaymentMap = {};
    var userPrepaidsMap = {};
    for (var i = 0; i < prepaids.length; i++) {
      if (!(prepaids[i].properties && prepaids[i].properties.trialRequestID)) {
        var userID = prepaids[i].creator.valueOf();
        prepaidIDs.push(new ObjectId(prepaids[i]._id));
        prepaidPaymentMap[prepaids[i]._id] = {prepaid: prepaids[i]}
        if (!userPrepaidsMap[userID]) userPrepaidsMap[userID] = [];
        userPrepaidsMap[userID].push(prepaids[i]);
      }
    }
    return done(prepaidIDs, prepaidPaymentMap, userPrepaidsMap);
  });
}

function getDisconnectedPrepaidUsers(db, prepaidIDs, prepaidPaymentMap, done) {
  db.collection('payments').find({prepaidID: {$in: prepaidIDs}}).toArray(function (err, payments) {
    if (err) {
      console.log(err);
      return done([]);
    }
    for (var i = 0; i < payments.length; i++) {
      prepaidPaymentMap[payments[i].prepaidID].payment = payments[i];
    }
    var missingUserIDs = [];
    for (var prepaidID in prepaidPaymentMap) {
      if (!prepaidPaymentMap[prepaidID].payment) {
        missingUserIDs.push(prepaidPaymentMap[prepaidID].prepaid.creator);
      }
    }
    return done(missingUserIDs);
  });
}

function getDisconnectedCharges(db, missingUserIDs, done) {
  db.collection('payments').find({$and: [{purchaser: {$in: missingUserIDs}}, {service: 'stripe'}]}, {amount: 1, prepaidID: 1, stripe: 1}).toArray(function (err, payments) {
    if (err) {
      console.log(err);
      return done({}, []);
    }
    var chargePaymentMap = {};
    var disconnectedCharges = [];
    for (var i = 0; i < payments.length; i++) {
      if (!payments[i].prepaidID && payments[i].stripe && payments[i].stripe.chargeID) {
        disconnectedCharges.push(payments[i].stripe.chargeID);
        chargePaymentMap[payments[i].stripe.chargeID] = payments[i];
      }
    }
    return done(chargePaymentMap, disconnectedCharges);
  });
}

function attachPrepaidsToPayments(db, chargePaymentMap, disconnectedCharges, userPrepaidsMap, done) {
  var processCharge = function(disconnectedCharge, done) {
    stripe.charges.retrieve(disconnectedCharge, function(err, charge) {
      var prepaid, payment;
      if (err) {
        console.log("Skipping error", disconnectedCharge);
      }
      else if (!charge) {
        console.log("Skipping not found", disconnectedCharge);
      }
      else if (!charge.metadata) {
        console.log('Skipping no metadata', disconnectedCharge);
      }
      else {
        var chargeUserID = charge.metadata.userID;
        var matches = [];
        for (var i = 0; i < userPrepaidsMap[chargeUserID].length; i++) {
          var currPrepaid = userPrepaidsMap[chargeUserID][i];
          if (charge.metadata.type === currPrepaid.type && parseInt(charge.metadata.maxRedeemers) === parseInt(currPrepaid.maxRedeemers)) {
            matches.push(currPrepaid);
          }
        }
        if (matches.length === 1) {
          payment = chargePaymentMap[charge.id];
          prepaid = matches[0];
          console.log("Saving prepaid", prepaid._id.valueOf(), 'to payment', payment._id.valueOf(), 'for user', chargeUserID, 'amount', chargePaymentMap[charge.id].amount);
        }
        else {
          console.log("No match", matches.length, 'user', chargeUserID, 'payment', chargePaymentMap[charge.id]._id.valueOf());
          if (matches.length > 1) console.log(matches);
        }
      }
      
      var next = function() {
        disconnectedCharges.shift();
        if (disconnectedCharges.length > 0) {
          return processCharge(disconnectedCharges[0], done);
        }
        return done();
      }

      if (payment && prepaid) {
        db.collection('payments').update({_id: new ObjectId(payment._id)}, {$set: {prepaidID: new ObjectId(prepaid._id)}}, function (err, response) {
          if (err) {
            console.log(err);
            return done();
          }
          if (!response || !response.result || response.result.nModified < 1) {
            console.log("Payment", payment._id, "not modified with prepaid", prepaid._id);
            console.log(response.result || response);
            return done();
          }
          return next();
        });
      }
      else {
        return next();
      } 
    });
  }
  processCharge(disconnectedCharges[0], function() {
    return done();
  });
}

// *** Helper functions ***

function log(str) {
  console.log(new Date().toISOString() + " " + str);
}

