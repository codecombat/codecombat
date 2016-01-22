// Delete unpaid gem payments based on Stripe charges
// Assumes prod env variables

var actuallyDeletePayments = false;

var async = require('async');
var apiKey = process.env.COCO_STRIPE_SECRET_KEY
var stripe = require("stripe")(apiKey);

var MongoClient = require('mongodb').MongoClient;
var mongoUrl = "mongodb://";
mongoUrl += process.env.COCO_MONGO_USERNAME + ":";
mongoUrl += process.env.COCO_MONGO_PASSWORD + "@";
mongoUrl += process.env.COCO_MONGO_HOST + ":" + process.env.COCO_MONGO_PORT + "/";
mongoUrl += process.env.MONGO_DATABASE_NAME;
console.log(mongoUrl);

function deleteUnpaidPayments(paymentsToDelete, done) {
  if (!actuallyDeletePayments) {
    console.log('Would have deleted unpaid payments: ' + paymentsToDelete.length);
    console.log(paymentsToDelete);
    return done();
  }

  console.log('Deleting unpaid payments... ' + paymentsToDelete.length);
  console.log(paymentsToDelete);
  MongoClient.connect(mongoUrl, function (err, db) {
    if (err) {
      console.log(err);
      return done();
    }
    db.collection('payments').remove({_id: {$in: paymentsToDelete}}, function(err, result) {
      if (err) {
        console.log(err);
        db.close()
        return done([]);
      }
      console.log(result.result);
      return done();
    });
  });
}

function findUnpaidPayments(payments) {
  console.log('Finding unpaid payments... ' + payments.length);
  var chargePaymentMap = {};
  var tasks = [];
  for (var i = 0; i < payments.length; i++) {
    chargePaymentMap[payments[i].stripe.chargeID] = payments[i];
    tasks.push(makeCheckCharge(payments[i].stripe.chargeID));
  }
  async.series(tasks, function(err, failedCharges) {
    var paymentsToDelete = [];
    if (err) {
      console.log(err);
    }
    else {
      for (var i = 0; i < failedCharges.length; i++) {
        var charge = failedCharges[i];
        if (!charge) continue;
        var payment = chargePaymentMap[charge.id];
        if (charge.id === payment.stripe.chargeID && parseInt(charge.metadata.timestamp) === payment.stripe.timestamp &&
          charge.metadata.userID == payment.purchaser) {
            paymentsToDelete.push(payment._id);
        }
        else {
          console.log("ERROR! " + charge.id);
          console.log(charge.metadata);
          console.log(chargePaymentMap[charge.id]);
          console.log(charge.metadata.userID === payment.purchaser);
          console.log(charge.metadata.userID == payment.purchaser);
          break;
        }
      }
    }

    deleteUnpaidPayments(paymentsToDelete, function() {
      console.log('Done.');
      process.exit();
    });
  });
}

function makeCheckCharge(chargeID) {
  return function(done) {
    stripe.charges.retrieve(chargeID, function(err, charge) {
      // Ignoring non-null err here because there are invalid (test) charges in our production database
      if (!err && charge.status === 'failed') {
        return done(null, charge);
      }
      return done();
    });
  };
}

function getPayments(done) {
  console.log('Fetching payments...');
  MongoClient.connect(mongoUrl, function (err, db) {
    if (err) {
      console.log(err);
      return done([]);
    }
    db.collection('payments').find({productID: {$exists: true}}).toArray(function(err, docs) {
      if (err) {
        console.log(err);
        db.close()
        return done([]);
      }
      return done(docs);
    });
  });
}

getPayments(findUnpaidPayments);
