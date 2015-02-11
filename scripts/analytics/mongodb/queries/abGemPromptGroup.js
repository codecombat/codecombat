// gemPromptGroup A/B Results
// Test started 2014-11-24

// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>

// Inputs to modify below:
// numDays - number of days into the past to fetch
// eventFunnel - ordered array of events that define the completion funnel
// levelSlugs - [optional] array of levels to examine, otherwise fetch all levels
// testGroupFn - return group value from user testGroupNumber

// Include getFunnelData(), log()
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

  log("Day\t\tGroup\t\tStarted\tFinished\tCompletion Rate");
  var overallCounts = {};
  for (var i = 0; i < funnelData.length; i++) {
    var level = funnelData[i].level;
    var day = funnelData[i].day;
    var group = funnelData[i].group;
    var started = funnelData[i].started;
    var finished = funnelData[i].finished;
    var rate = started > 0 ? finished / started * 100 : 0.0;

    if (!overallCounts[level]) overallCounts[level] = {};
    if (!overallCounts[level][group]) overallCounts[level][group] = {started: 0, finished: 0};
    overallCounts[level][group]['started'] += started;
    overallCounts[level][group]['finished'] += finished;

    if (group === 'prompt') {
      log(day + "\t" + group + "\t\t" + started + "\t" + finished + "\t" + rate.toFixed(2));
    }
    else {
      log(day + "\t" + group + "\t" + started + "\t" + finished + "\t" + rate.toFixed(2));
    }
  }

  log("Overall totals:");
  for (level in overallCounts) {
    for (group in overallCounts[level]) {
      var started = overallCounts[level][group].started;
      var finished = overallCounts[level][group].finished;
      var rate = started > 0 ? finished / started * 100 : 0.0;
      if (group === 'prompt') {
        log(group + "\t\t" + started + "\t" + finished + "\t" + rate.toFixed(2));
      }
      else {
        log(group + "\t" + started + "\t" + finished + "\t" + rate.toFixed(2));
      }
    }
  }
}
catch(err) {
  log("ERROR: " + err);
  printjson(err);
}
finally {
  log("Script runtime: " + (new Date() - scriptStartTime));
}
