// Insert older (-16 days) Stripe invoices into coco database analytics collection

if (process.argv.length !== 4) {
  log("Usage: node <script> <Stripe API key> <mongo connection Url>");
  process.exit();
}

var scriptStartTime = new Date();
var stripeAPIKey = process.argv[2];
var mongoConnUrl = process.argv[3];
var stripe = require("stripe")(stripeAPIKey);
var MongoClient = require('mongodb').MongoClient;

getInvoices(function(invoices) {
  log("Invoice count: " + invoices.length);
  insertInvoices(invoices, function() {
    log("Script runtime: " + (new Date() - scriptStartTime));
    process.exit(0);
  });
});

function log(str) {
  console.log(new Date().toISOString() + " " + str);
}

function getInvoices(done) {
  var sixteenDaysAgo = new Date()
  sixteenDaysAgo.setUTCDate(sixteenDaysAgo.getUTCDate() - 16);
  invoiceMaxTimestamp = Math.floor(sixteenDaysAgo.getTime() / 1000);
  var options = {limit: 100, date: {lt: invoiceMaxTimestamp}};
  var invoices = [];

  getInvoicesHelper = function(options, done) {
    // log("getInvoicesHelper " + invoices.length + " " + options.starting_after);
    stripe.invoices.list(options, function (err, result) {
      if (err) {
        console.log(err);
        return;
      }
      invoices = invoices.concat(result.data);
      if (result.has_more) {
        options.starting_after = result.data[result.data.length - 1].id
        getInvoicesHelper(options, done);
      }
      else {
        done(invoices);
      }
    });
  };
  getInvoicesHelper(options, done);
}

function insertInvoices(invoices, done) {
  var docs = [];
  for (var i = 0; i < invoices.length; i++) {
    docs.push({
      _id: invoices[i].id,
      date: invoices[i].date,
      properties: invoices[i]
    });
  }

  MongoClient.connect(mongoConnUrl, function (err, db) {
    if (err) {
      console.log(err);
      return done();
    }

    insertInvoicesHelper = function() {
      var doc = docs.pop();
      if (!doc) {
        db.close();
        return done();
      }
      db.collection('analytics.stripe.invoices').save(doc, function(err, result) {
        if (err) {
          console.log(err);
          db.close();
          return done();
        }
        insertInvoicesHelper();
      });
    };
    insertInvoicesHelper();
  });
}
