// showsPortal A/B Results
// Test started 2015-02-05, ended 2015-02-26
// Final results: seems to help people get to the later levels, and at least definitely doesn't hurt:
// dungeons-of-kithgard false   64605   49956   77.33
// dungeons-of-kithgard true    65380   50590   77.38
// gems-in-the-deep     false   45339   40788   89.96
// gems-in-the-deep     true    45922   41455   90.27
// kithgard-gates       false   7415    6904    93.11
// kithgard-gates       true    7783    7249    93.14
// kounter-kithwise     true    95      92      96.84
// kounter-kithwise     false   86      77      89.53
// rich-forager         false   1067    822     77.04
// rich-forager         true    1111    834     75.07
// shadow-guard         false   38089   35239   92.52
// shadow-guard         true    38774   35975   92.78
// the-mighty-sand-yak  true    505     400     79.21
// the-mighty-sand-yak  false   425     329     77.41
// 
// Group totals:
// false  157026  134115  85.41
// true   159570  136595  85.60


// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>

load('abTestHelpers.js');

var scriptStartTime = new Date();
try {
  var startDay = '2015-02-05'
  log("Today is " + new Date().toISOString().substr(0, 10));
  log("Start day is " + startDay);

  var eventFunnel = ['Started Level', 'Saw Victory'];
  var levelSlugs = ['dungeons-of-kithgard', 'gems-in-the-deep', 'shadow-guard', 'kounter-kithwise', 'kithgard-gates', 'rich-forager', 'the-mighty-sand-yak'];

  // getShowsPortal
  var testGroupFn = function (testGroupNumber) {
    return testGroupNumber < 128;
  }

  var funnelData = getFunnelData(startDay, eventFunnel, testGroupFn, levelSlugs);

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
