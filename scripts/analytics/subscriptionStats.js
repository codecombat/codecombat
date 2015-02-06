// To use: set the range you want below, make sure your environment has the stripe key, then run:
// node scripts/analytics/subscriptions.js 

require('coffee-script');
require('coffee-script/register');
config = require('../../server_config');
if(config.stripe.secretKey.indexOf('sk_test_')==0) {
  throw new Error('You should not run this on the test data... Get your environment in gear.');
}

stripe = require('stripe')(config.stripe.secretKey);

var range = {
  gt: ''+(new Date('2015-01-01').getTime()/1000),
  lt: ''+(new Date('2015-02-01').getTime()/1000)
}; 

begin = function(starting_after) {
  var query = {date: range, limit: 100};
  if(starting_after) {
    query.starting_after = starting_after;
  }
  stripe.invoices.list(query, onInvoicesReceived);
}

customersPaid = []

onInvoicesReceived = function(err, invoices) {
  for(var i in invoices.data) {
    var invoice = invoices.data[i];
    if(!invoice.paid) { continue; }
    customersPaid.push(invoice.customer);
  }
  if(invoices.has_more) {
    console.log('Loaded', customersPaid.length, 'invoices.')
    begin(invoices.data[i].id);
  }
  else {
    console.log('How many customers paid for a subscription:', customersPaid.length);
    loadNewCustomers();
  }
}

loadNewCustomers = function(starting_after) {
  query = {created: range, limit: 100};
  if(starting_after) {
    query.starting_after = starting_after;
  }
  stripe.customers.list(query, onCustomersReceived);
}

newCustomersPaid = [];

onCustomersReceived = function(err, customers) {
  for(var i in customers.data) {
    var customer = customers.data[i];
    if(customersPaid.indexOf(customer.id) == -1) { continue; }
    newCustomersPaid.push(customer.id);
  }
  if(customers.has_more) {
    console.log('Loaded', newCustomersPaid.length, 'new customers.');
    loadNewCustomers(customers.data[i].id);
  }
  else {
    console.log('How many new customers paid for a subscription:', newCustomersPaid.length);
  }
}

begin();