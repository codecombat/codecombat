// Print out subscribers by special country (China, Brazil)

// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>

function displayMoney(amount) {
  return '$' + (amount / 100).toFixed(2);
};

var countries = [
  {country: {$exists: false}, countryCode: 'US'},
  {country: 'united-states', countryCode: 'US'},
  {country: 'china', countryCode: 'CN'},
  {country: 'brazil', countryCode: 'BR'},

  // Loosely ordered by decreasing traffic as measured 2016-09-01 - 2016-11-07
  {country: 'united-kingdom', countryCode: 'GB'},
  {country: 'russia', countryCode: 'RU'},
  {country: 'australia', countryCode: 'AU'},
  {country: 'canada', countryCode: 'CA'},
  {country: 'france', countryCode: 'FR'},
  {country: 'taiwan', countryCode: 'TW'},
  {country: 'ukraine', countryCode: 'UA'},
  {country: 'poland', countryCode: 'PL'},
  {country: 'spain', countryCode: 'ES'},
  {country: 'germany', countryCode: 'DE'},
  {country: 'netherlands', countryCode: 'NL'},
  {country: 'hungary', countryCode: 'HU'},
  {country: 'japan', countryCode: 'JP'},
  {country: 'turkey', countryCode: 'TR'},
  {country: 'south-africa', countryCode: 'ZA'},
  {country: 'indonesia', countryCode: 'ID'},
  {country: 'new-zealand', countryCode: 'NZ'},
  {country: 'finland', countryCode: 'FI'},
  {country: 'south-korea', countryCode: 'KR'},
  {country: 'mexico', countryCode: 'MX'},
  {country: 'vietnam', countryCode: 'VN'},
  {country: 'singapore', countryCode: 'SG'},
  {country: 'colombia', countryCode: 'CO'},
  {country: 'india', countryCode: 'IN'},
  {country: 'thailand', countryCode: 'TH'},
  {country: 'belgium', countryCode: 'BE'},
  {country: 'sweden', countryCode: 'SE'},
  {country: 'denmark', countryCode: 'DK'},
  {country: 'czech-republic', countryCode: 'CZ'},
  {country: 'hong-kong', countryCode: 'HK'},
  {country: 'italy', countryCode: 'IT'},
  {country: 'romania', countryCode: 'RO'},
  {country: 'belarus', countryCode: 'BY'},
  {country: 'norway', countryCode: 'NO'},
  {country: 'philippines', countryCode: 'PH'},
  {country: 'lithuania', countryCode: 'LT'},
  {country: 'argentina', countryCode: 'AR'},
  {country: 'malaysia', countryCode: 'MY'},
  {country: 'pakistan', countryCode: 'PK'},
  {country: 'serbia', countryCode: 'RS'},
  {country: 'greece', countryCode: 'GR'},
  {country: 'israel', countryCode: 'IL'},
  {country: 'portugal', countryCode: 'PT'},
  {country: 'slovakia', countryCode: 'SK'},
  {country: 'ireland', countryCode: 'IE'},
  {country: 'switzerland', countryCode: 'CH'},
  {country: 'peru', countryCode: 'PE'},
  {country: 'bulgaria', countryCode: 'BG'},
  {country: 'venezuela', countryCode: 'VE'},
  {country: 'austria', countryCode: 'AT'},
  {country: 'croatia', countryCode: 'HR'},
  {country: 'saudia-arabia', countryCode: 'SA'},
  {country: 'chile', countryCode: 'CL'},
  {country: 'united-arab-emirates', countryCode: 'AE'},
  {country: 'kazakhstan', countryCode: 'KZ'},
  {country: 'estonia', countryCode: 'EE'},
  {country: 'iran', countryCode: 'IR'},
  {country: 'egypt', countryCode: 'EG'},
  {country: 'ecuador', countryCode: 'EC'},
  {country: 'slovenia', countryCode: 'SI'},
  {country: 'macedonia', countryCode: 'MK'}
]

function isLifetime(user) {
  if (user.role) return false;
  if (user.payPal && !user.payPal.billingAgreementID && ! user.payPal.cancelDate) return true;
  if (!user.stripe) return false;
  if (user.stripe.free == true) return true;
  return false;
}

function hasSubscription(user) {
  if (user.role) return false;
  if (user.payPal && user.payPal.billingAgreementID) return true;
  if (!user.stripe) return false;
  if (user.stripe.sponsorID) return true;
  if (user.stripe.subscriptionID) return true;
  if (user.stripe.free == true) return true;
  if (user.stripe.free && new Date() < new Date(user.stripe.free)) return true;
  return false;
}

var spreadsheetLines = [];
countries.forEach(function(countryObj) {
  var country = countryObj.country;
  print('---' + country.toUpperCase() + '---');
  var userQuery = {country: country, role: {$exists: false}, $or: [{'stripe.sponsorID': {$exists: true}}, {'stripe.subscriptionID': {$exists: true}}, {'stripe.free': {$exists: true}}, {'stripe.customerID': {$exists: true}}, {paypal: {$exists: true}}]};
  var usersToDo = db.users.count(userQuery);
  var cursor = db.users.find(userQuery, {email: 1, country: 1, stripe: 1, name: 1, dateCreated: 1, role: 1, payPal: 1}).noCursorTimeout();
  var users = [];
  var total = 0;
  var activeCount = 0;
  var lifetimeCount = 0;
  var paymentAmounts = [];
  var usersSeen = 0;
  try {
    while (cursor.hasNext()) {
      var user = cursor.next();
      ++usersSeen;
      var payments = db.payments.find({recipient: user._id}, {amount: 1}).toArray();
      var amount = 0;
      payments.forEach(function(payment) {
        if (!(payment.amount && payment.amount > 0 && payment.amount < 999999)) {
          if (payment.amount)
            print("Skipping bogus payment amount", payment.amount, "for payment", payment._id);
          return;
        }
        if (payment.amount && typeof payment.amount == "string") {
          payment.amount = parseInt(payment.amount);
          print("Converting payment", payment.amount, "from string to number for payment", payment._id);
        }
        amount += payment.amount;
        paymentAmounts.push(payment.amount);
      });
      total += amount;
      if (total > 100000000) {
        print(total, amount);
        ohno()
      }
      if (!amount) {
        continue;
      }
      var lifetime = isLifetime(user);
      var active = hasSubscription(user) && !lifetime;
      if (active) ++activeCount;
      if (lifetime) ++lifetimeCount;
      users.push(user);
      print([usersSeen, usersToDo, displayMoney(amount), active ? 'Active' : (lifetime ? 'Lifetime' : ''), user.dateCreated, user._id, user.country, user.email, user.name, JSON.stringify(user.stripe, null, 0)].join('\t'));
    }
  }
  catch (err) {
    cursor.close();
    print(err);
  }
  paymentAmounts.sort();
  var medianAmount = paymentAmounts[Math.floor(paymentAmounts.length / 2)];
  print('Got', displayMoney(total), 'over', activeCount, 'active subscribers,', lifetimeCount, 'lifetime subscribers, and', users.length - activeCount - lifetimeCount, 'former subscribers in', country, 'with median payment of', displayMoney(medianAmount), '\n');
  spreadsheetLines.push([displayMoney(total), activeCount, lifetimeCount, users.length - activeCount - lifetimeCount, country, displayMoney(medianAmount)].join('\t'));
});

print("Total subscription revenue\t# active subscribers\t# lifetime subscribers\t# former subscribers\tCountry\tMedian payment");
print(spreadsheetLines.join('\n'));
