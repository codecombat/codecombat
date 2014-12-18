// Evaluate help videos styles A/B test

// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>

// What do we want to know?
// For a given style:
// - Video completion rates (Not too interesting unless each level has all styles available)
// - Video completion rates, per-level too
// TODO: The rest of these.
// - Watched another video
// - Level completion rates
// - Subscription coversion rates
// - How many people who start a level click the help button, and which one?
//    - Need a hard start date when the help button presented


// Intial production deploy completed at 12:42am 12/18/14 PST
var testStartDate='2014-12-14T08:42:00.000Z';

function printVideoCompletionRates() {
  print("Querying for help video events...");
  var videosCursor = db['analytics.log.events'].find({
    $and: [
    {"created": { $gte: ISODate(testStartDate)}},
    {$or : [
      {"event": "Start help video"},
      {"event": "Finish help video"}
      ]}
      ]
    });


  print("Building video progression data...");
  // Build: <style><level><userID><event> counts
  var videoProgression = {};
  while (videosCursor.hasNext()) {
    var doc = videosCursor.next();
    var userID = doc.user.valueOf();
    var levelID = doc.properties.level;
    var style = doc.properties.style;
    var event = doc.event;
    if (!videoProgression[style]) videoProgression[style] = {};
    if (!videoProgression[style][levelID]) videoProgression[style][levelID] = {};
    if (!videoProgression[style][levelID][userID]) videoProgression[style][levelID][userID] = {};
    if (!videoProgression[style][levelID][userID][event]) videoProgression[style][levelID][userID][event] = 0;
    videoProgression[style][levelID][userID][event]++;
  }

  // Overall per-style

  print("Counting start/finish events per-style...");
  // Calculate overall video style completion rates, agnostic of level
  // Build: <style><event>{<starts>, <finishes>}
  var styleCompletionCounts = {}
  for (style in videoProgression) {
    styleCompletionCounts[style] = {};
    for (levelID in videoProgression[style]) {
      for (userID in videoProgression[style][levelID]) {
        for (event in videoProgression[style][levelID][userID]) {
          if (!styleCompletionCounts[style][event]) styleCompletionCounts[style][event] = 0;
          styleCompletionCounts[style][event] += videoProgression[style][levelID][userID][event];
        }
      }
    }
  }

  print("Sorting per-style completion rates...");
  var styleCompletionRates = [];
  for (style in styleCompletionCounts) {
    var started = 0;
    var finished = 0;
    for (event in styleCompletionCounts[style]) {
      if (event === "Start help video") started += styleCompletionCounts[style][event];
      else if (event === "Finish help video") finished += styleCompletionCounts[style][event];
      else throw new Error("Unknown event " + event);
    }
    var data = {
      style: style,
      started: started,
      finished: finished
    };
    if (finished > 0) data['rate'] = finished / started * 100;
    styleCompletionRates.push(data);
  }
  styleCompletionRates.sort(function(a,b) {return b['rate'] && a['rate'] ? b.rate - a.rate : 0;});

  print("Overall per-style completion rates:");
  for (var i = 0; i < styleCompletionRates.length; i++) {
    var item = styleCompletionRates[i];
    var msg = item.style + (item.style === 'edited' ? "\t\t" : "\t") + item.started + "\t" + item.finished;
    if (item['rate']) msg += "\t" + item.rate + "%";
    print(msg);
  }

  // Style completion rates per-level

  print("Counting start/finish events per-level and style...");
  var styleLevelCompletionCounts = {}
  for (style in videoProgression) {
    for (levelID in videoProgression[style]) {
      if (!styleLevelCompletionCounts[levelID]) styleLevelCompletionCounts[levelID] = {};
      if (!styleLevelCompletionCounts[levelID][style]) styleLevelCompletionCounts[levelID][style] = {};
      for (userID in videoProgression[style][levelID]) {
        for (event in videoProgression[style][levelID][userID]) {
          if (!styleLevelCompletionCounts[levelID][style][event]) styleLevelCompletionCounts[levelID][style][event] = 0;
          styleLevelCompletionCounts[levelID][style][event] += videoProgression[style][levelID][userID][event];
        }
      }
    }
  }

  print("Sorting per-level completion rates...");
  var styleLevelCompletionRates = [];
  for (levelID in styleLevelCompletionCounts) {
    for (style in styleLevelCompletionCounts[levelID]) {
      var started = 0;
      var finished = 0;
      for (event in styleLevelCompletionCounts[levelID][style]) {
        if (event === "Start help video") started += styleLevelCompletionCounts[levelID][style][event];
        else if (event === "Finish help video") finished += styleLevelCompletionCounts[levelID][style][event];
        else throw new Error("Unknown event " + event);
      }
      var data = {
        level: levelID,
        style: style,
        started: started,
        finished: finished
      };
      if (finished > 0) data['rate'] = finished / started * 100;
      styleLevelCompletionRates.push(data);
    }
  }
  styleLevelCompletionRates.sort(function(a,b) {return b['rate'] && a['rate'] ? b.rate - a.rate : 0;});
  
  print("Per-level style completion rates:");
  for (var i = 0; i < styleLevelCompletionRates.length; i++) {
    var item = styleLevelCompletionRates[i];
    var msg = item.level + "\t" + item.style + "\t" + item.started + "\t" + item.finished;
    if (item['rate']) msg += "\t" + item.rate + "%";
    print(msg);
  }
}
printVideoCompletionRates();