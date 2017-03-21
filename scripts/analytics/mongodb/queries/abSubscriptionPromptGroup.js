// subscriptionPromptGroup A/B Results
// Test started 2015-09-18, ended 2015-11-22
// Final results:
// Subscribers by group: {
//   "tactical-strike": 246,
//   "boom-and-bust": 255,
//   "favorable-odds": 303
// }

// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>
// Except actually now you run these scripts on the analytics server itself.
// https://docs.google.com/document/d/1d5mOsTjioX2KRNAqhWXdGyBevuhxSPH1xX7UWlYPpwk/edit#

load('abTestHelpers.js');

var scriptStartTime = new Date();
try {
  var logDB = new Mongo("localhost").getDB("analytics");
  var startDay = '2015-09-18';
  log("Today is " + new Date().toISOString().substr(0, 10));
  log("Start day is " + startDay);

  var eventFunnel = ['Started Level', 'Saw Victory'];
  var levelSlugs = ['dungeons-of-kithgard', 'gems-in-the-deep', 'shadow-guard', 'forgetful-gemsmith', 'true-names', 'favorable-odds', 'the-raised-sword', 'lowly-kithmen', 'closing-the-distance', 'tactical-strike', 'a-mayhem-of-munchkins', 'kithgard-gates', 'boom-and-bust', 'defense-of-plainswood'];

  // getSubscriptionPromptGroup
  var testGroupFn = function (testGroupNumber) {
    var group = testGroupNumber % 3;
    if (group === 0) return 'favorable-odds';
    if (group === 1) return 'tactical-strike';
    if (group === 2) return 'boom-and-bust';
  };

  var funnelData = getFunnelData(startDay, eventFunnel, testGroupFn, levelSlugs, logDB);

  printFunnelData(funnelData, function (day, level, browser, group, started, finished, rate) {
    if (day && level && browser && group) {
      log(day + "\t" + group + "\t" + started + "\t" + finished + "\t" + rate.toFixed(2));
    }
    else if (level && browser && group) {
      log(level + "\t" + browser + "\t" + (browser.length < 8 ? "\t": "") + group  + "\t" + started + "\t" + finished + "\t" + rate.toFixed(2));
    }
    else if (level && group) {
      log(level + "\t" + group + "\t" + started + "\t" + finished + "\t" + rate.toFixed(2));
    }
    else if (group) {
      log(group + "\t" + started + "\t" + finished + "\t" + rate.toFixed(2));
    }
  });
}
catch(err) {
  log("ERROR: " + err);
  printjson(err);
}
finally {
  log("Script runtime: " + (new Date() - scriptStartTime));
}
