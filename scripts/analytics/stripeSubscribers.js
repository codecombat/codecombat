// Find latest Stripe basic subscribers who haven't cancelled

if (process.argv.length !== 3) {
  console.log("Usage: node <script> <API key>");
  process.exit();
}

var apiKey = process.argv[2];
var stripe = require("stripe")(apiKey);

var yesterday = new Date();
yesterday.setUTCDate(yesterday.getUTCDate() - 1);

stripe.customers.list({ limit: 40 }, function(err, customers) {
  // asynchronously called
  for (var i = 0; i < customers.data.length; i++) {
    var customer = customers.data[i];
    var created = new Date(customer.created * 1000);
    // console.log(created, yesterday);
    // if (created > yesterday) continue;

    if (customer.subscriptions && customer.subscriptions.data.length > 0) {
      var basic = false;
      // console.log(customer.id + " " + created.toISOString() + " " + customer.email);
      for (var j = 0;j < customer.subscriptions.data.length; j++) {
        var subscription = customer.subscriptions.data[j];
        // console.log(subscription.id + " " + subscription.plan.id + " " + subscription.cancel_at_period_end);
        if (subscription.plan.id === 'basic') {
          if (subscription.cancel_at_period_end === false) {
            basic = true;
            break;
          }
          // else {
          //   console.log("CANCELLED", customer.id);
          // }
        }
      }
      if (basic) {
        console.log(created.toISOString(), customer.email);
      }
      // else {
      //   console.log("NO SUB", customer.id);
      // }
    }
  }
});
