// Print out subscribers by special country (China, Brazil)

// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>

function displayMoney(amount) {
    return '$' + (amount / 100).toFixed(2);
};

var countries = ['brazil', 'china', 'israel'];
countries.forEach(function(country) {
    print('---' + country.toUpperCase() + '---');
    var cursor = db.users.find({country: country, stripe: {$exists: true}}, {email: 1, country: 1, stripe: 1, name: 1, dateCreated: 1});
    var users = [];
    var total = 0;
    var activeCount = 0;
    while (cursor.hasNext()) {
        var user = cursor.next();
	var payments = db.payments.find({recipient: user._id});
        var amount = 0;
	payments.forEach(function(payment) {
	    amount += payment.amount;
	});
        total += amount;
	if (!amount) {
            continue;
	}
        var active = !!user.stripe.subscriptionID;
        if (active) ++activeCount;
	users.push(user);
	print([displayMoney(amount), active ? 'Active' : '', user.dateCreated, user._id, user.country, user.email, user.name, JSON.stringify(user.stripe, null, 0)].join('\t'));
    }
    print('Got', displayMoney(total), 'over', activeCount, 'active subscribers and', users.length - activeCount, 'former subscribers in', country, '\n');
});
