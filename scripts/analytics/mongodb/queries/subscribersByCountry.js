// Print out subscribers by special country (China, Brazil)

// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>

var countries = ['brazil', 'china'];
countries.forEach(function(country) {
  print('---' + country.toUpperCase() + '---');
  var cursor = db.users.find({country: country, stripe: {$exists: true}}, {email: 1, country: 1, stripe: 1, name: 1});
  var users = [];
  var inactiveUsers = [];
  while (cursor.hasNext()) {
    var user = cursor.next();
    if (!user.stripe.subscriptionID) {
      inactiveUsers.push(user);
      continue;
    }
    users.push(user);
    print([user._id, user.country, user.email, user.name, JSON.stringify(user.stripe, null, 0)].join('\t'));
  }
  print('Had', users.length, 'active subscribers and', inactiveUsers.length, 'possible former subscribers in', country, '\n');
});
