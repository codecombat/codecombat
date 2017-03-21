// Evaluate help videos styles A/B test

// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>

// What do we want to know?
// For a given style:
// - Video completion rates (Not too interesting unless each level has all styles available)
// - Video completion rates, per-level too
// - Watched another video
// - Level completion rates
// - Subscription coversion totals
// - TODO: Check guide opens after haunted-kithmaze

// TODO: look at date ranges before and after 2nd prod deploy

// 12:42am 12/18/14 PST - Intial production deploy completed
var testStartDate = '2014-12-18T08:42:00.000Z';
// 12:29pm 12/18/14 PST - 2nd deploy w/ originals for dungeons-of-kithgard and second-kithmaze
// testStartDate = '2014-12-18T20:29:00.000Z';
// Moved this date up to avoid prod deploy transitional data messing with us.
testStartDate = '2014-12-18T22:29:00.000Z';

// Only print the levels we have multiple styles for
var multiStyleLevels = ['dungeons-of-kithgard', 'haunted-kithmaze'];

var g_videoEventCounts = {};
function initVideoEventCounts() {
  // Per-level/style event counts to use for comparison correction later
  // We have a weird sampling problem that doesn't yield equal test buckets

  print("Querying for help video events...");
  var cursor = db['analytics.log.events'].find({
    $and: [
    {"created": { $gte: ISODate(testStartDate)}},
    {$or: [
    {"event": "Start help video"},
    {"event": "Finish help video"}
    ]}
    ]
  });

  while (cursor.hasNext()) {
    var doc = cursor.next();
    var levelID = doc.properties.level;
    var style = doc.properties.style;
    var event = doc.event;
    if (!g_videoEventCounts[levelID]) g_videoEventCounts[levelID] = {};
    if (!g_videoEventCounts[levelID][style]) g_videoEventCounts[levelID][style] = {};
    if (!g_videoEventCounts[levelID][style][event]) g_videoEventCounts[levelID][style][event] = 0;
    g_videoEventCounts[levelID][style][event]++;
  }
  // printjson(g_videoEventCounts);
}

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

  // print("Building video progression data...");
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
  // TODO: Not too useful unless we have all styles for each level
  
  // // print("Counting start/finish events per-style...");
  // // Calculate overall video style completion rates, agnostic of level
  // // Build: <style><event>{<starts>, <finishes>}
  // var styleCompletionCounts = {}
  // for (style in videoProgression) {
  //   styleCompletionCounts[style] = {};
  //   for (levelID in videoProgression[style]) {
  //     for (userID in videoProgression[style][levelID]) {
  //       for (event in videoProgression[style][levelID][userID]) {
  //         if (!styleCompletionCounts[style][event]) styleCompletionCounts[style][event] = 0;
  //         styleCompletionCounts[style][event] += videoProgression[style][levelID][userID][event];
  //       }
  //     }
  //   }
  // }
  // 
  // // print("Sorting per-style completion rates...");
  // var styleCompletionRates = [];
  // for (style in styleCompletionCounts) {
  //   var started = 0;
  //   var finished = 0;
  //   for (event in styleCompletionCounts[style]) {
  //     if (event === "Start help video") started += styleCompletionCounts[style][event];
  //     else if (event === "Finish help video") finished += styleCompletionCounts[style][event];
  //     else throw new Error("Unknown event " + event);
  //   }
  //   var data = {
  //     style: style,
  //     started: started,
  //     finished: finished
  //   };
  //   if (finished > 0) data['rate'] = finished / started * 100;
  //   styleCompletionRates.push(data);
  // }
  // styleCompletionRates.sort(function(a,b) {return b['rate'] && a['rate'] ? b.rate - a.rate : 0;});
  // 
  // // print("Overall per-style completion rates:");
  // for (var i = 0; i < styleCompletionRates.length; i++) {
  //   var item = styleCompletionRates[i];
  //   var msg = item.style + (item.style === 'edited' ? "\t\t" : "\t") + item.started + "\t" + item.finished;
  //   if (item['rate']) msg += "\t" + item.rate + "%";
  //   print(msg);
  // }

  // Style completion rates per-level

  // print("Counting start/finish events per-level and style...");
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

  // print("Sorting per-level completion rates...");
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
  styleLevelCompletionRates.sort(function(a,b) {
    if (a.level !== b.level) {
      if (a.level < b.level) return -1;
      else return 1;
    }
    return b['rate'] && a['rate'] ? b.rate - a.rate : 0;
  });

  print("Per-level style completion rates:");
  for (var i = 0; i < styleLevelCompletionRates.length; i++) {
    var item = styleLevelCompletionRates[i];
    if (multiStyleLevels.indexOf(item.level) >= 0) {
      var msg = item.level + "\t" + item.style + (item.style === 'edited' ? "\t\t" : "\t") + item.started + "\t" + item.finished;
      if (item['rate']) msg += "\t" + item.rate.toFixed(2) + "%";
      print(msg);
    }
  }
}

function printWatchedAnotherVideoRates() {
  // How useful is a style/level in yielding more video starts
  // Algorithm:
  // 1. Fetch all start/finish video events after test start date
  // 2. Create a per-userID dictionary of user event history arrays
  // 3. Sort each user event history array in ascending order.  Now we have a video watching history, per-user.
  // 4. Walk through each user's history
  //    a. Increment global count for level/style/event, for each level/style event in past history.
  //    b. Save current entry in the past history.
  // 5. Sort by ascending level name, descending started count

  // TODO: only attribute one start/finish per level to a user?

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

  // print("Building per-user video progression data...");
  // Find video progression per-user
  // Build: <userID>[sorted style/event/level/date events]
  var videoProgression = {};
  while (videosCursor.hasNext()) {
    var doc = videosCursor.next();
    var event = doc.event;
    var userID = doc.user.valueOf();
    var created = doc.created
    var levelID = doc.properties.level;
    var style = doc.properties.style;

    if (!videoProgression[userID]) videoProgression[userID] = [];
    videoProgression[userID].push({
      style: style,
      level: levelID,
      event: event,
      created: created.toISOString()
    })
  }
  // printjson(videoProgression);

  // print("Sorting per-user video progression data...");
  for (userID in videoProgression) videoProgression[userID].sort(function (a,b) {return a.created < b.created ? -1 : 1});

  // print("Building per-level/style additional watched videos..");
  var additionalWatchedVideos = {};
  for (userID in videoProgression) {

    // Walk user's history, and tally what preceded each historical entry
    var userHistory = videoProgression[userID];
    // printjson(userHistory);
    var previouslyWatched = {};
    for (var i = 0; i < userHistory.length; i++) {

      // Walk previously watched events, and attribute to correct additionally watched entry
      var item = userHistory[i];
      var level = item.level;
      var style = item.style;
      var event = item.event;
      var created = item.created;
      for (previousLevel in previouslyWatched) {
        for (previousStyle in previouslyWatched[previousLevel]) {
          if (previousLevel === level) continue;
          // For previous level and style, 'event' followed it
          if (!additionalWatchedVideos[previousLevel]) additionalWatchedVideos[previousLevel] = {};
          if (!additionalWatchedVideos[previousLevel][previousStyle]) {
            additionalWatchedVideos[previousLevel][previousStyle] = {};
          }
          // TODO: care which video watched next?
          if (!additionalWatchedVideos[previousLevel][previousStyle][event]) {
            additionalWatchedVideos[previousLevel][previousStyle][event] = 0;
          }
          additionalWatchedVideos[previousLevel][previousStyle][event]++;
          // if (previousLevel === 'the-second-kithmaze') {
          //   print("Followed the-second-kithmaze " + userID + " " + level + " " + event + " " + created);
          // }
        }
      }

      // Add level/style to previouslyWatched for this user
      if (!previouslyWatched[level]) previouslyWatched[level] = {};
      if (!previouslyWatched[level][style]) previouslyWatched[level][style] = true;
    }
  }

  // print("Sorting additional watched videos by started event counts...");
  var additionalWatchedVideoByStarted = [];
  for (levelID in additionalWatchedVideos) {
    for (style in additionalWatchedVideos[levelID]) {
      var started = 0;
      var finished = 0;
      for (event in additionalWatchedVideos[levelID][style]) {
        if (event === "Start help video") started += additionalWatchedVideos[levelID][style][event];
        else if (event === "Finish help video") finished += additionalWatchedVideos[levelID][style][event];
        else throw new Error("Unknown event " + event);
      }
      var data = {
        level: levelID,
        style: style,
        started: started,
        finished: finished,
        startAgainRate: started / g_videoEventCounts[levelID][style]['Start help video'] * 100,
        finishAgainRate: finished / g_videoEventCounts[levelID][style]['Finish help video'] * 100
      };
      additionalWatchedVideoByStarted.push(data);
    }
  }
  additionalWatchedVideoByStarted.sort(function(a,b) {
    if (a.level !== b.level) {
      if (a.level < b.level) return -1;
      else return 1;
    }
    return b.startAgainRate - a.startAgainRate;
  });

  print("Per-level additional videos watched:");
  print("For a given level and style, this is how many more videos were started and finished.");
  print("Columns: level, style, started, finished, started again rate, finished again rate");
  for (var i = 0; i < additionalWatchedVideoByStarted.length; i++) {
    var item = additionalWatchedVideoByStarted[i];
    if (multiStyleLevels.indexOf(item.level) >= 0) {
      print(item.level + "\t" + item.style + (item.style === 'edited' ? "\t\t" : "\t") + item.started + "\t" + item.finished + "\t" + item.startAgainRate.toFixed(2) + "%\t" + item.finishAgainRate.toFixed(2) + "%");
    }
  }
}

function printLevelCompletionRates() {
  // For a level/style, how many completed that same level
  // For a level/style, how many levels were completed afterwards?

  // Find each started event, per user
  print("Querying for help video events...");
  var eventsCursor = db['analytics.log.events'].find({
    $and: [
    {"created": { $gte: ISODate(testStartDate)}},
    {$or : [
      {"event": "Start help video"},
      {"event": "Saw Victory"}
    ]}
  ]
  });

  // print("Building per-user events progression data...");
  // Find event progression per-user
  var eventsProgression = {};
  while (eventsCursor.hasNext()) {
    var doc = eventsCursor.next();
    var event = doc.event;
    var userID = doc.user.valueOf();
    var created = doc.created
    var levelID = doc.properties.level;
    var style = doc.properties.style;
    if (event === 'Saw Victory') levelID = levelID.toLowerCase().replace(/ /g, '-');
    if (!eventsProgression[userID]) eventsProgression[userID] = [];
    eventsProgression[userID].push({
      style: style,
      level: levelID,
      event: event,
      created: created.toISOString()
    })
  }

  // print("Sorting per-user events progression data...");
  for (userID in eventsProgression) eventsProgression[userID].sort(function (a,b) {return a.created < b.created ? -1 : 1});

  // print("Building per-level/style levels completed..");
  var levelsCompletedCounts = {};
  var sameLevelCompletedCounts = {};
  for (userID in eventsProgression) {
    
    // Walk user's history, and tally what preceded each historical entry
    var userHistory = eventsProgression[userID];
    var previouslyWatched = {};
    for (var i = 0; i < userHistory.length; i++) {
      
      // Walk previously watched events, and attribute to correct additionally watched entry
      var item = userHistory[i];
      var level = item.level;
      var style = item.style;
      var event = item.event;
      var created = item.created;
      
      if (event === 'Start help video') {
        // Add level/style to previouslyWatched for this user
        if (!previouslyWatched[level]) previouslyWatched[level] = {};
        if (!previouslyWatched[level][style]) previouslyWatched[level][style] = true;
      
      }
      else if (event === 'Saw Victory') {
        for (previousLevel in previouslyWatched) {
          for (previousStyle in previouslyWatched[previousLevel]) {
            if (previousLevel === level) {
              if (!sameLevelCompletedCounts[previousLevel]) sameLevelCompletedCounts[previousLevel] = {};
              if (!sameLevelCompletedCounts[previousLevel][previousStyle]) {
                sameLevelCompletedCounts[previousLevel][previousStyle] = 0;
              }
              sameLevelCompletedCounts[previousLevel][previousStyle]++;
            } 
            // For previous level and style, Saw Victory followed it
            if (!levelsCompletedCounts[previousLevel]) levelsCompletedCounts[previousLevel] = {};
            if (!levelsCompletedCounts[previousLevel][previousStyle]) {
              levelsCompletedCounts[previousLevel][previousStyle] = 0;
            }
            levelsCompletedCounts[previousLevel][previousStyle]++;
          }
        }
      }
      else {
        throw new Error("Unknown event " + event);
      }
    }
  }
  
  // print("Sorting level completed counts...");
  var levelsCompletedSorted = [];
  for (levelID in levelsCompletedCounts) {
    for (style in levelsCompletedCounts[levelID]) {
      var data = {
        level: levelID,
        style: style,
        completed: levelsCompletedCounts[levelID][style],
        completedPerPlayer: levelsCompletedCounts[levelID][style] / g_videoEventCounts[levelID][style]['Start help video']
      };
      levelsCompletedSorted.push(data);
    }
  }
  levelsCompletedSorted.sort(function(a,b) {
    if (a.level !== b.level) {
      if (a.level < b.level) return -1;
      else return 1;
    }
    return b.completedPerPlayer - a.completedPerPlayer;
  });

  print("Total levels completed after video watched:");
  print("Columns: level, style, levels completed, completed per player");
  for (var i = 0; i < levelsCompletedSorted.length; i++) {
    var item = levelsCompletedSorted[i];
    if (multiStyleLevels.indexOf(item.level) >= 0) {
      print(item.level + "\t" + item.style + (item.style === 'edited' ? "\t\t" : "\t") + item.completed + "\t" + item.completedPerPlayer.toFixed(2));
    }
  }
  
  var sameLevelCompletedSorted = [];
  for (levelID in sameLevelCompletedCounts) {
    for (style in sameLevelCompletedCounts[levelID]) {
      var data = {
        level: levelID,
        style: style,
        completed: sameLevelCompletedCounts[levelID][style],
        completionRate: sameLevelCompletedCounts[levelID][style] / g_videoEventCounts[levelID][style]['Start help video'] * 100
      };
      sameLevelCompletedSorted.push(data);
    }
  }
  sameLevelCompletedSorted.sort(function(a,b) {
    if (a.level !== b.level) {
      if (a.level < b.level) return -1;
      else return 1;
    }
    return b.completionRate - a.completionRate;
  });
  
  print("Same level completed after video watched:");
  print("Columns: level, style, same level completed, completion rate");
  for (var i = 0; i < sameLevelCompletedSorted.length; i++) {
    var item = sameLevelCompletedSorted[i];
    if (multiStyleLevels.indexOf(item.level) >= 0) {
      print(item.level + "\t" + item.style + (item.style === 'edited' ? "\t\t" : "\t") + item.completed + "\t" + item.completionRate.toFixed(2) + "%");
    }
  }
}

function printSubConversionTotals() {
  // For a user, who started a video, did they subscribe afterwards?

  // Find each started event, per user
  print("Querying for help video start events...");
  var eventsCursor = db['analytics.log.events'].find({
    $and: [
      {"created": { $gte: ISODate(testStartDate)}},
      {$or : [
        {"event": "Start help video"},
        {"event": "Finished subscription purchase"}
        ]}
    ]
  });

  // print("Building per-user events progression data...");
  // Find event progression per-user
  var eventsProgression = {};
  while (eventsCursor.hasNext()) {
    var doc = eventsCursor.next();
    var event = doc.event;
    var userID = doc.user.valueOf();
    var created = doc.created
    var levelID = doc.properties.level;
    var style = doc.properties.style;
    
    if (!eventsProgression[userID]) eventsProgression[userID] = [];
    eventsProgression[userID].push({
      style: style,
      level: levelID,
      event: event,
      created: created.toISOString()
    })
  }

  // print("Sorting per-user events progression data...");
  for (userID in eventsProgression) eventsProgression[userID].sort(function (a,b) {return a.created < b.created ? -1 : 1});
  
  // print("Building per-level/style sub purchases..");
  // Build: <level><style><count>
  var subPurchaseCounts = {};
  for (userID in eventsProgression) {
    var history = eventsProgression[userID];
    for (var i = 0; i < history.length; i++) {
      if (history[i].event === 'Finished subscription purchase') {
        var item = i > 0 ? history[i - 1] : {level: 'unknown', style: 'unknown'};
        if (!subPurchaseCounts[item.level]) subPurchaseCounts[item.level] = {};
        if (!subPurchaseCounts[item.level][item.style]) subPurchaseCounts[item.level][item.style] = 0;
        subPurchaseCounts[item.level][item.style]++;
      }
    }
  }
  
  // print("Sorting per-level/style sub purchase counts...");
  var subPurchasesByTotal = [];
  for (levelID in subPurchaseCounts) {
    for (style in subPurchaseCounts[levelID]) {
      subPurchasesByTotal.push({
        level: levelID,
        style: style,
        total: subPurchaseCounts[levelID][style]
      })
    }
  }
  subPurchasesByTotal.sort(function (a,b) {
    if (a.level !== b.level) return a.level < b.level ? -1 : 1;
    return b.total - a.total;
  });
  
  print("Per-level/style following sub purchases:");
  print("Columns: level, style, following sub purchases.");
  print("'unknown' means no preceding start help video event.");
  for (var i = 0; i < subPurchasesByTotal.length; i++) {
    var item = subPurchasesByTotal[i];
    if (multiStyleLevels.indexOf(item.level) >= 0) {
      print(item.level + "\t" + item.style + (item.style === 'edited' ? "\t\t" : "\t") + item.total);
    }
  }
}

function printHelpClicksPostHaunted() {
  // For a level/style, how many completed that same level
  // For a level/style, how many levels were completed afterwards?
  
  // Find each started event, per user
  print("Querying for help video events...");
  var eventsCursor = db['analytics.log.events'].find({
    $and: [
    {"created": { $gte: ISODate(testStartDate)}},
    {$or : [
      {$and:[{"event": "Start help video"}, {"properties.level": 'haunted-kithmaze'}]},
      {"event": "Problem alert help clicked"},
      {"event": "Spell palette help clicked"},
      ]}
    ]
  });

  // print("Building per-user events progression data...");
  // Find event progression per-user
  var eventsProgression = {};
  while (eventsCursor.hasNext()) {
    var doc = eventsCursor.next();
    var event = doc.event;
    var userID = doc.user.valueOf();
    var created = doc.created
    var levelID = doc.properties.level;
    var style = doc.properties.style;
    if (!eventsProgression[userID]) eventsProgression[userID] = [];
    eventsProgression[userID].push({
      style: style,
      level: levelID,
      event: event,
      created: created.toISOString()
    })
  }

  // print("Sorting per-user events progression data...");
  for (userID in eventsProgression) eventsProgression[userID].sort(function (a,b) {return a.created < b.created ? -1 : 1});

  // print("Building per-level/style levels completed..");
  var helpClickCounts = {};
  for (userID in eventsProgression) {
    // Walk user's history, and tally what preceded each historical entry
    var userHistory = eventsProgression[userID];
    var previouslyWatched = {};
    for (var i = 0; i < userHistory.length; i++) {
      
      // Walk previously watched events, and attribute to correct additionally watched entry
      var item = userHistory[i];
      var level = item.level;
      var style = item.style;
      var event = item.event;
      var created = item.created;
      
      if (event === 'Start help video') {
        // Add level/style to previouslyWatched for this user
        if (!previouslyWatched[level]) previouslyWatched[level] = {};
        if (!previouslyWatched[level][style]) previouslyWatched[level][style] = true;
      }
      else if (event === "Problem alert help clicked" || event === "Spell palette help clicked") {
        for (previousLevel in previouslyWatched) {
          for (previousStyle in previouslyWatched[previousLevel]) {
            // For previous level and style, help click followed it
            if (!helpClickCounts[previousLevel]) helpClickCounts[previousLevel] = {};
            if (!helpClickCounts[previousLevel][previousStyle]) helpClickCounts[previousLevel][previousStyle] = 0;
            helpClickCounts[previousLevel][previousStyle]++;
          }
        }
      }
      else {
        throw new Error("Unknown event " + event);
      }
    }
  }

  // print("Sorting level completed counts...");
  var helpClicksSorted = [];
  for (levelID in helpClickCounts) {
    for (style in helpClickCounts[levelID]) {
      var data = {
        level: levelID,
        style: style,
        completed: helpClickCounts[levelID][style],
        completedPerPlayer: helpClickCounts[levelID][style] / g_videoEventCounts[levelID][style]['Start help video']
      };
      helpClicksSorted.push(data);
    }
  }
  helpClicksSorted.sort(function(a,b) {
    if (a.level !== b.level) {
      if (a.level < b.level) return -1;
      else return 1;
    }
    return b.completedPerPlayer - a.completedPerPlayer;
  });

  print("Helps clicked after video watched:");
  print("Columns: level, style, click count, clicks per start video");
  for (var i = 0; i < helpClicksSorted.length; i++) {
    var item = helpClicksSorted[i];
    if (multiStyleLevels.indexOf(item.level) >= 0) {
      print(item.level + "\t" + item.style + (item.style === 'edited' ? "\t\t" : "\t") + item.completed + "\t" + item.completedPerPlayer.toFixed(2));
    }
  }
}

initVideoEventCounts();
printVideoCompletionRates();

printWatchedAnotherVideoRates();
printLevelCompletionRates();
printSubConversionTotals();
printHelpClicksPostHaunted();
