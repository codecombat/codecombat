// foreshadowsLevels A/B Results
// Test started 2015-01-29, ended 2015-02-26
// Fixed some particle problems on 2015-02-02
// Fixed more particle problems in old browsers on 2015-02-19
// Final results: tests showed no difference in completion rates, but slight drops in level start rates for non-Chrome browsers, so we stopped doing it outside of Chrome.

// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>

load('abTestHelpers.js');

var scriptStartTime = new Date();
try {
  var startDay = '2015-02-20';
  log("Today is " + new Date().toISOString().substr(0, 10));
  log("Start day is " + startDay);

  var eventFunnel = ['Started Level', 'Saw Victory'];
  var levelSlugs = ['dungeons-of-kithgard', 'gems-in-the-deep', 'shadow-guard', 'forgetful-gemsmith', 'kounter-kithwise', 'kithgard-gates', 'rich-forager', 'village-guard'];

  // getForeshadowsLevels
  var testGroupFn = function (testGroupNumber) {
    var group = testGroupNumber % 16
    return group >= 0 && group <= 7;
  };

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
