// gemPromptGroup A/B Results
// Test started 2014-11-24

// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>

load('abTestHelpers.js');

var scriptStartTime = new Date();
try {
  var startDay = '2014-11-24'
  log("Today is " + new Date().toISOString().substr(0, 10));
  log("Start day is " + startDay);

  var eventFunnel = ['Started purchase', 'Finished gem purchase'];

  // getGemPromptGroup
  var testGroupFn = function (testGroupNumber) {
    var group = testGroupNumber % 8
    return group >= 0 && group <= 3 ? 'prompt' : 'no-prompt';
  }

  var funnelData = getFunnelData(startDay, eventFunnel, testGroupFn);

  printFunnelData(funnelData, function (day, level, browser, group, started, finished, rate) {
    if (day && level && browser && group) {
      log(day + "\t" + group + "\t" + (group === 'prompt' ? "\t": "") + started + "\t" + finished + "\t" + rate.toFixed(2));
    }
    else if (group) {
      log(group + (group === 'prompt' ? "\t": "") + "\t" + started + "\t" + finished + "\t" + rate.toFixed(2));
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
