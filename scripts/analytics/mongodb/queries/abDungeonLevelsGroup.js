// Print out average player level by dungeon levels group

// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>

var cursor = db.users.find({dateCreated: {$gt: new Date(2016, 10, 8), $lt: new Date(2016,10,29)}}, {points: 1, stripe: 1, stats: 1, dateCreated: 1, testGroupNumber: 1});
var groups = [
    'control',
    'conservative',
    'cell-commentary',
    'kithgard-librarian',
    'loop-da-loop',
    'haunted-kithmaze',
    'none'
];
var users = {};
var points = {};
var levels = {};
var activeCount = {};
groups.forEach(function(g) {
    users[g] = [];
    points[g] = 0;
    levels[g] = 0;
    activeCount[g] = 0;
});
while (cursor.hasNext()) {
    var user = cursor.next();
    if (!user.stats || !(user.stats.gamesCompleted > 5)) continue;  // Hasn't even gotten to the test yet.
    if (!(user.points > 3000)) continue;
    var groupNumber = user.testGroupNumber % 7;
    var group = groups[groupNumber];
    var amountPaid = 0;
    if (user.stripe) {
	var payments = db.payments.find({recipient: user._id});
	payments.forEach(function(payment) {
	    amountPaid += payment.amount;
	});
    }	
    var active = amountPaid > 0;
    if (active) ++activeCount[group];
    users[group].push(user);
    points[group] += user.points || 0;
    levels[group] += user.stats.gamesCompleted;
    //print([group, active ? 'Active' : '', user.points, (user.stats || {}).gamesCompleted || 0].join('\t'));
}

groups.forEach(function(g) {
    var num = users[g].length;
    var ratio = 1;
    if (g == "loop-da-loop" || g == "haunted-kithmaze" || g == "none") ratio = 36 / 35;
    print(pad(20, g, ' '), '\tgot', (activeCount[g] * ratio).toFixed(1), 'active subscribers,', (num * ratio).toFixed(0), 'players,', Math.round(points[g] / num), 'points, and', (levels[g] / num).toFixed(1), 'levels.');
});

function pad(width, string, padding) { 
  return (width <= string.length) ? string : pad(width, padding + string, padding)
}

