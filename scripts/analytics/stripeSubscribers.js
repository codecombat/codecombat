// Find latest Stripe basic subscribers who haven't cancelled

// TODO: doesn't handle 11+ sponsored subs for a given customer

if (process.argv.length !== 3) {
  console.log("Usage: node <script> <API key>");
  process.exit();
}

var apiKey = process.argv[2];
var stripe = require("stripe")(apiKey);

var yesterday = new Date();
yesterday.setUTCDate(yesterday.getUTCDate() - 1);

var earliestDate = new Date("2015-03-01T00:00:00.000Z");

var subs = {};

getSubscriptions(null, function () {
  console.log('Recurring sub counts:');
  for (var created in subs) {
    for (var amount in subs[created]) {
      if (parseInt(amount) > 0) {
        console.log(created, amount, subs[created][amount]['recurring'])
      }
    }
  }
});


function getSubscriptions(starting_after, done)
{
  var options = {limit: 100};
  if (starting_after) options.starting_after = starting_after;

  stripe.customers.list(options, function(err, customers) {
    for (var i = 0; i < customers.data.length; i++) {
      var customer = customers.data[i];

      if (customer.subscriptions && customer.subscriptions.data.length > 0) {
        var basic = false;
        for (var j = 0;j < customer.subscriptions.data.length; j++) {
          var subscription = customer.subscriptions.data[j];
          if (subscription.plan.id === 'basic') {

            var created = new Date(subscription.start * 1000);
            if (created < earliestDate) continue;
            created = created.toISOString().substring(0, 10);
            if (!subs[created]) subs[created] = {};

            var amount = subscription.plan.amount;
            if (subscription.discount && subscription.discount.coupon) {
              if (subscription.discount.coupon.percent_off) {
                amount = amount *  (100 - subscription.discount.coupon.percent_off) / 100;
              }
              else if (subscription.discount.coupon.amount_off) {
                amount -= subscription.discount.coupon.amount_off;
              }
            }
            else if (customer.discount && customer.discount.coupon) {
              if (customer.discount.coupon.percent_off) {
                amount = amount *  (100 - customer.discount.coupon.percent_off) / 100;
              }
              else if (customer.discount.coupon.amount_off) {
                amount -= customer.discount.coupon.amount_off;
              }
            }

            if (!subs[created][amount]) subs[created][amount] = {};

            if (subscription.cancel_at_period_end === true) {
              if (!subs[created][amount]['cancelled']) subs[created][amount]['cancelled'] = 0;
              subs[created][amount]['cancelled']++;
            }
            else {
              if (!subs[created][amount]['recurring']) subs[created][amount]['recurring'] = {};

              if (customer.alipay_accounts && customer.alipay_accounts.total_count) {
                if (!subs[created][amount]['recurring']['alipay']) subs[created][amount]['recurring']['alipay'] = 0;
                subs[created][amount]['recurring']['alipay']++;
              }
              else {
                if (!subs[created][amount]['recurring']['card']) subs[created][amount]['recurring']['card'] = 0;
                subs[created][amount]['recurring']['card']++;
              }
            }
          }
        }
      }
    }
    if (customers.has_more) {
      getSubscriptions(customers.data[customers.data.length - 1].id, done);
    }
    else {
      done();
    }
  });
}
