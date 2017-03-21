'use strict';
// Output Hints style a/b test results in csv format

if (process.argv.length !== 5) {
  log("Usage: node <script> <mongo connection Url> <mongo connection Url level session> <mongo connection Url analytics>");
  log("Include ?readPreference=secondary in connection URLs");
  process.exit();
}

// Hints v1 eng done around 6/20/16, content roughly 7/15/16, ideally would pull roughly from 6/20/16

// Styles:
// group = me.get('testGroupNumber') % 3
// @hintsGroup = switch group
//   when 0 then 'no-hints' # Only intro/overview
//   when 1 then 'hints'   # Automatically created code, doled out line-by-line, without full solutions
//   when 2 then 'hintsB'  # Manually created FAQ-style hints, reusable across levels

// Question: how does hint style affect long term student success?
// Distance, speed, future hints usage, per student
// Per-level speeds
// Need to control against copy/paste nature of line-by-line style
// 58 levels have hints (automatic line-by-line style)
// 52 levels have hintsB (manual FAQ-style)

// Restrict to classroom
// Control for hints discoverability:

// TODO: drill into level progression
// TODO: javascript vs. python
// TODO: target specifically hard levels, and ignore strict level progression (i.e. just X number levels before target)

const scriptStartTime = new Date();

const mongoConnUrl = process.argv[2];
const mongoConnUrlLevelSessions = process.argv[3];
const mongoConnUrlAnalytics = process.argv[4];

const mongoose = require('mongoose');
const MongoClient = require('mongodb').MongoClient;
const Promise = require('bluebird');
const genstats = require('genstats');

const debugOutput = true;
const rawOutput = false;

// TODO: 3+ home months => JavaScript heap out of memory
const startDay = "2016-10-25";
const classroomVersion = false; // false == home

Promise.all([
  MongoClient.connect(mongoConnUrl),
  MongoClient.connect(mongoConnUrlLevelSessions),
  MongoClient.connect(mongoConnUrlAnalytics),
])
.then((databases) => {
  const [db, levelSessionDb, analyticsDb] = [databases[0], databases[1], databases[2]];
  // TODO: better way to pass along data between promises?
  let levelIds, orderedLevels, levelStyleMap, userIds, userStyleMap;
  (()=> classroomVersion ? getClassroomOrderedLevels(db) : getHomeOrderedLevels(db))()
  .then((results) => {
    [levelIds, orderedLevels] = results;
    return getLevelStyleMap(db, levelIds);
  })
  .then((results) => {
    levelStyleMap = results;
    return getUsers(db, startDay, classroomVersion);
  })
  .then((results) => {
    [userIds, userStyleMap] = results;
    return getHintsAndLevelSessions(analyticsDb, levelSessionDb, levelIds, userIds);
  })
  .then((results) => {
    const [userFirstHintViewedLevelMap, userLevelHintEventsMap] = getHintMaps(levelStyleMap, results[0], orderedLevels);
    const userLevelSessionsMap = getLevelSessionMapAndMaybePrintRawOutput(results[1], levelStyleMap, orderedLevels, userFirstHintViewedLevelMap, userLevelHintEventsMap, userStyleMap);
    outputResults(levelStyleMap, orderedLevels, userFirstHintViewedLevelMap, userLevelSessionsMap, userStyleMap);

    databases.forEach((db) => db.close());
    debug(`Script runtime: ${new Date() - scriptStartTime}`);
  })
  .catch((err) => {
    console.log(err);
    databases.forEach((db) => db.close());
    debug(`Script runtime: ${new Date() - scriptStartTime}`);
  });
});

// * Helper functions

function debug(msg) {
  if (debugOutput) console.log(`${new Date().toISOString()} ${msg}`);
}

function objectIdWithTimestamp(timestamp) {
  // Convert string date to Date object (otherwise assume timestamp is a date)
  if (typeof(timestamp) == 'string') timestamp = new Date(timestamp);
  // Convert date object to hex seconds since Unix epoch
  var hexSeconds = Math.floor(timestamp/1000).toString(16);
  // Create an ObjectId with that hex timestamp
  var constructedObjectId = mongoose.Types.ObjectId(hexSeconds + "0000000000000000");
  return constructedObjectId;
}

function getMedian(values) {
  if (values.length === 0) return -1;
  values.sort((a, b) => a - b);
  const lowMiddle = Math.floor((values.length - 1) / 2);
  const highMiddle = Math.ceil((values.length - 1) / 2);
  return (values[lowMiddle] + values[highMiddle]) / 2;
}

function getMedianAbsoluteDeviation(values, median) {
  if (!median) median = getMedian(values);
  const absoluteDeviations = values.map((a) => Math.abs(a - median));
  absoluteDeviations.sort((a, b) => a - b);
  return getMedian(absoluteDeviations);
}

function getClassroomOrderedLevels(db) {
  debug(`DEBUG: fetching sorted classroom levels..`);
  const courseCampaignMap = {};
  const orderedCourses = [];
  const campaignIds = [];
  return db.collection('courses').find({releasePhase: 'released'}, {campaignID: 1}).toArray()
  .then((courses) => {
    for (var course of courses) {
      courseCampaignMap[course._id.toString()] = course.campaignID.toString();
      campaignIds.push(course.campaignID);
      orderedCourses.push(course._id.toString());
    }
    sortCourses(orderedCourses);
    return db.collection('campaigns').find({_id: {$in: campaignIds}}, {levels: 1}).toArray();
  })
  .then((campaigns) => {
    const campaignLevelsMap = {};
    for (var campaign of campaigns) {
      campaignLevelsMap[campaign._id.toString()] = campaign.levels;
    }
    const orderedLevels = [];
    const levelIds = [];
    for (var courseId of orderedCourses) {
      if (campaignLevelsMap[courseCampaignMap[courseId]]) {
        const levelMap = campaignLevelsMap[courseCampaignMap[courseId]];
        for (var levelId in levelMap) {
          // console.log(courseId, levelMap[levelId].slug);
          orderedLevels.push(levelMap[levelId].slug);
          levelIds.push(mongoose.Types.ObjectId(levelId));
        }
      }
      else {
        debug(`DEBUG: no campaign levels for course ${courseId}`);
      }
    }
    debug(`DEBUG: ${orderedLevels.length} levels found`);
    return [levelIds, orderedLevels];
  });
}

function getHomeOrderedLevels(db) {
  const testCampaignId = mongoose.Types.ObjectId("57684da18391c22600817154");
  return db.collection('campaigns').find({type: 'hero', _id: {$ne: testCampaignId}}, {levels: 1}).toArray()
  .then((campaigns) => {
    const campaignLevelsMap = {};
    for (var campaign of campaigns) {
      campaignLevelsMap[campaign._id.toString()] = campaign.levels;
    }
    const orderedCampaigns = Object.keys(campaignLevelsMap);
    sortHeroCampaigns(orderedCampaigns);
    // printjson(orderedCampaigns)
    const orderedLevels = [];
    const levelIds = [];
    for (var campaignId of orderedCampaigns) {
      if (campaignLevelsMap[campaignId]) {
        const levelMap = campaignLevelsMap[campaignId];
        const campaignLevels = [];
        for (var levelId in levelMap) {
          campaignLevels.push(levelMap[levelId]);
          levelIds.push(mongoose.Types.ObjectId(levelId));
        }
        campaignLevels.sort((a, b) => a.campaignIndex - b.campaignIndex);
        for (var level of campaignLevels) {
          // console.log(campaignId, level.slug);
          orderedLevels.push(level.slug);
        }
      }
      else {
        debug(`DEBUG: no campaign levels for campaig ${campaignId}`);
      }
    }
    debug(`DEBUG: ${orderedLevels.length} levels found`);
    return [levelIds, orderedLevels];
  });
}

function getLevelStyleMap(db, levelIds) {
  const levelStyleMap = {};
  return db.collection('levels').find(
    {original: {$in: levelIds}, documentation: {$exists: 1}},
    {documentation: 1, slug: 1}
    ).toArray()
  .then((levels) => {
    for (var level of levels) {
      if (!level.slug) continue;
      if (!levelStyleMap[level.slug]) levelStyleMap[level.slug] = {};
      if (level.documentation.hints) levelStyleMap[level.slug]['automatic'] = level.documentation.hints.length;
      if (level.documentation.hintsB) levelStyleMap[level.slug]['manual'] = level.documentation.hintsB.length;
      for (var article of level.documentation.specificArticles || []) {
        if (article.name === 'Intro') levelStyleMap[level.slug].intro = true;
        if (article.name === 'Overview') levelStyleMap[level.slug].overview = true;
        if (levelStyleMap[level.slug].intro && levelStyleMap[level.slug].overview) break;
      }
    }
    return levelStyleMap;
  });
}

function getUsers(db, startDay, inClassroom=true) {
  debug(`DEBUG: fetching users created after ${startDay}..`);
  const startObjectId = objectIdWithTimestamp(new Date(`${startDay}T00:00:00.000Z`));
  const userStyleMap = {};
  const userIds = [];
  const query = {_id: {$gte: startObjectId}, anonymous: false};
  query.role = inClassroom ? 'student' : {$exists: false};
  return db.collection('users').find(query, {role: 1, testGroupNumber: 1}).toArray()
  .then((users) => {
    for (var user of users) {
      userIds.push(user._id.toString());
      switch (user.testGroupNumber % 3) {
        case 0:
          userStyleMap[user._id.toString()] = 'no-hints';
          break;
        case 1:
          userStyleMap[user._id.toString()] = 'automatic';
          break;
        case 2:
          userStyleMap[user._id.toString()] = 'manual';
          break;
      }
    }
    debug(`DEBUG: ${userIds.length} users found`);
    return [userIds, userStyleMap];
  });
}

function getHintsAndLevelSessions(analyticsDb, levelSessionDb, levelIds, userIds) {
  debug(`DEBUG: fetching level sessions and hints..`);
  const levelIdStrings = levelIds.map((levelId) => levelId.toString());
  const eventPromises = [];
  const levelSessionPromises = [];
  const userBatchSize = Math.round(userIds.length / 40);
  for (let i = 0; i * userBatchSize < userIds.length; i++) {
    const start = i * userBatchSize;
    const end = Math.min(i * userBatchSize + userBatchSize - 1, userIds.length - 1);
    eventPromises.push(
      analyticsDb.collection('log').find(
      {user: {$in: userIds.slice(start, end)}, event: {$in: ['Hints Clicked', 'Hints Next Clicked']}},
      {event: 1, properties: 1, user: 1}
      ).toArray()
    );
    levelSessionPromises.push(
      levelSessionDb.collection('level.sessions').find(
      {$and: [{creator: {$in: userIds.slice(start, end)}}, {'level.original': {$in: levelIdStrings}}, {'state.complete': true}]},
      {created: 1, creator: 1, 'level.original': 1, levelID: 1, playtime: 1}
      ).toArray()
    );
  }
  return Promise.all([Promise.all(eventPromises), Promise.all(levelSessionPromises)]);
}

function getHintMaps(levelStyleMap, logEventsList, orderedLevels) {
  const userFirstHintViewedLevelMap = {};
  const userLevelHintEventsMap = {};
  for (var logEvents of logEventsList) {
    for (var logEvent of logEvents) {
      const userId = logEvent.user;
      const levelSlug = logEvent.properties.levelSlug;
      const userStyle = logEvent.properties.hintsGroup;
      if (orderedLevels.indexOf(levelSlug) < 0) continue;

      if (!userLevelHintEventsMap[userId]) userLevelHintEventsMap[userId] = {};
      if (!userLevelHintEventsMap[userId][levelSlug]) userLevelHintEventsMap[userId][levelSlug] = [];
      userLevelHintEventsMap[userId][levelSlug].push(logEvent);

      // Save earliest level the user viewed a hint
      if (logEvent.event === 'Hints Next Clicked' && (levelStyleMap[levelSlug]['automatic'] || levelStyleMap[levelSlug]['manual'])) {
        if (!userFirstHintViewedLevelMap[userId] || orderedLevels.indexOf(levelSlug) < orderedLevels.indexOf(userFirstHintViewedLevelMap[userId])) {
          userFirstHintViewedLevelMap[userId] = levelSlug;
        }
      }
    }
  }
  debug(`DEBUG: ${logEventsList.reduce((a, b) => a + b.length, 0)} hint events found`);
  return [userFirstHintViewedLevelMap, userLevelHintEventsMap];
}

function getLevelSessionMapAndMaybePrintRawOutput(levelSessionsList, levelStyleMap, orderedLevels, userFirstHintViewedLevelMap, userLevelHintEventsMap, userStyleMap) {
  // TODO: split up these two objectives
  const userLevelSessionsMap = {};
  if (rawOutput) console.log(`levelSessionId,levelSlug,levelIndex,userId,playtime,userStyle,hintsButtonClicked,hintViews,numHintsForUserStyle,firstHintsLevelSlug`);
  for (var levelSessions of levelSessionsList) {
    for (var levelSession of levelSessions) {
      if (!levelSession.levelID) continue;
      if (!levelStyleMap[levelSession.levelID]) {
        // debug(`DEBUG: no level style for ${levelSession.levelID}, skipping level session`);
        continue;
      }

      const levelSessionId = levelSession._id.toString();
      const levelSlug = levelSession.levelID;
      const levelIndex = orderedLevels.indexOf(levelSlug) >= 0 ? orderedLevels.indexOf(levelSlug) : 9000;
      const userId = levelSession.creator;
      const playtime = levelSession.playtime;
      const userStyle = userStyleMap[userId];
      var hintsButtonClicked = false;
      const hintsViewed = {};
      var numHintsForUserStyle = levelStyleMap[levelSlug][userStyle] || 0;
      const firstHintsLevelSlug = userFirstHintViewedLevelMap[userId] || '';
      if (userLevelHintEventsMap[userId]) {
        for (var logEvent of userLevelHintEventsMap[userId][levelSlug] || []) {
          if (!hintsButtonClicked && logEvent.event === 'Hints Clicked') {
            hintsButtonClicked = true;
            numHintsForUserStyle = parseInt(logEvent.properties.hintCount);
            if (levelStyleMap[levelSlug].intro) numHintsForUserStyle--;
            if (levelStyleMap[levelSlug].overview) numHintsForUserStyle--;
            if (!levelStyleMap[levelSlug].intro) hintsViewed[0] = true;
          }
          else if (logEvent.event == 'Hints Next Clicked') {
            // TODO: not correct if current num hints different from time of log event
            var hintsIndex = parseInt(logEvent.properties.hintCurrent) + 1;
            if (levelStyleMap[levelSlug].intro) hintsIndex--;
            if (hintsIndex < numHintsForUserStyle) hintsViewed[hintsIndex] = true;
          }
        }
      }
      const hintViews = Object.keys(hintsViewed).length;
      if (rawOutput) console.log(`${levelSessionId},${levelSlug},${levelIndex},${userId},${playtime},${userStyle},${hintsButtonClicked},${hintViews},${numHintsForUserStyle},${firstHintsLevelSlug}`);

      if (firstHintsLevelSlug) {
        if (!userLevelSessionsMap[levelSession.creator]) userLevelSessionsMap[levelSession.creator] = [];
        userLevelSessionsMap[levelSession.creator].push(levelSession);
      }
    }
  }
  debug(`DEBUG: ${levelSessionsList.reduce((a, b) => a + b.length, 0)} level sessions found`);
  debug(`DEBUG: ${Object.keys(userLevelSessionsMap).length} hint used level sessions found`);
  return userLevelSessionsMap;
}

function outputResults(levelStyleMap, orderedLevels, userFirstHintViewedLevelMap, userLevelSessionsMap, userStyleMap) {
  debug(`DEBUG: crunching user data..`)
  const levelStylePlaytimesMap = {}; // level, style, playtimes
  for (var userId in userLevelSessionsMap) {
    const userStyle = userStyleMap[userId];
    for (var levelSession of userLevelSessionsMap[userId]) {
      const levelSlug = levelSession.levelID;
      // If this level is at or past user's first hints view, then save info
      if (orderedLevels.indexOf(userFirstHintViewedLevelMap[userId]) <= orderedLevels.indexOf(levelSlug)) {
        if (!levelStylePlaytimesMap[levelSlug]) levelStylePlaytimesMap[levelSlug] = {};
        if (!levelStylePlaytimesMap[levelSlug][userStyle]) levelStylePlaytimesMap[levelSlug][userStyle] = [];
        levelStylePlaytimesMap[levelSlug][userStyle].push(levelSession.playtime || 0);
      }
    }
  }

  const orderedStyles = ['no-hints', 'automatic', 'manual'];
  console.log(`,,,no-hints,,,,,automatic,,,,,manual,,,,,p-values,,Min playtimes,,`);
  console.log(`level,has automatic,has manual,users,MAD,Q1,median,Q3,users,MAD,Q1,median,Q3,users,MAD,Q1,median,Q3,automatic,manual,Q1,median,Q3`);
  for (var levelSlug of orderedLevels) {
    if (!levelStylePlaytimesMap[levelSlug]) continue;
    const stylePlaytimesMap = levelStylePlaytimesMap[levelSlug];
    const styleData = {};
    var output = levelSlug;
    output += `,${levelStyleMap[levelSlug]['automatic'] ? 'automatic' : ''}`;
    output += `,${levelStyleMap[levelSlug]['manual'] ? 'manual' : ''}`;
    orderedStyles.forEach((style) => {
      styleData[style] = {users: 0, median: -1, medianAbsoluteDeviation: -1, q1: -1, q3: -1};
      if (stylePlaytimesMap[style]) {
        styleData[style].users = stylePlaytimesMap[style].length;
        if (styleData[style].users >= 3) {
          styleData[style].median = getMedian(stylePlaytimesMap[style]);
          styleData[style].medianAbsoluteDeviation = getMedianAbsoluteDeviation(stylePlaytimesMap[style], styleData[style].median);
          // TODO: total dupe of getMedian work
          // TODO: this only happens to be sorted!
          const lowMiddle = Math.floor((stylePlaytimesMap[style].length - 1) / 2);
          const highMiddle = Math.ceil((stylePlaytimesMap[style].length - 1) / 2);
          const medianIndex = (lowMiddle + highMiddle) / 2;
          styleData[style].q1 = getMedian(stylePlaytimesMap[style].slice(0, Math.floor(medianIndex) + 1));
          styleData[style].q3 = getMedian(stylePlaytimesMap[style].slice(Math.floor(medianIndex + 1), stylePlaytimesMap[style].length));
        }
      }
      output += `,${styleData[style].users},${styleData[style].medianAbsoluteDeviation},${styleData[style].q1},${styleData[style].median},${styleData[style].q3}`;
    })

    if (Math.min.apply(null, orderedStyles.map((style) => Math.min.apply(null, ['q1', 'median', 'q3'].map((a) => styleData[style][a])))) === -1) {
      output += `,n/a,n/a,n/a`;
    }
    else {
      // Automatic and manual p-values
      const automaticWelch = genstats.welch(stylePlaytimesMap['no-hints'], stylePlaytimesMap['automatic']);
      const manualWelch = genstats.welch(stylePlaytimesMap['no-hints'], stylePlaytimesMap['manual']);
      output += `,${automaticWelch.p.toFixed(4)},${manualWelch.p.toFixed(4)}`;

      // Style min playtimes
      const q1s = orderedStyles.map((style) => styleData[style].q1);
      const medians = orderedStyles.map((style) => styleData[style].median);
      const q3s = orderedStyles.map((style) => styleData[style].q3);
      output += `,${orderedStyles.filter((style) => Math.min.apply(null, q1s) === styleData[style].q1)[0]}`
      output += `,${orderedStyles.filter((style) => Math.min.apply(null, medians) === styleData[style].median)[0]}`
      output += `,${orderedStyles.filter((style) => Math.min.apply(null, q3s) === styleData[style].q3)[0]}`
    }
    console.log(output);
  }
}

function sortCourses(courses) {
  const courseIDs = {
    INTRODUCTION_TO_COMPUTER_SCIENCE: '560f1a9f22961295f9427742',
    COMPUTER_SCIENCE_2: '5632661322961295f9428638',
    GAME_DEVELOPMENT_1: '5789587aad86a6efb573701e',
    WEB_DEVELOPMENT_1: '5789587aad86a6efb573701f',
    COMPUTER_SCIENCE_3: '56462f935afde0c6fd30fc8c',
    GAME_DEVELOPMENT_2: '57b621e7ad86a6efb5737e64',
    WEB_DEVELOPMENT_2: '5789587aad86a6efb5737020',
    COMPUTER_SCIENCE_4: '56462f935afde0c6fd30fc8d',
    COMPUTER_SCIENCE_5: '569ed916efa72b0ced971447',
  };
  const orderedCourseIDs = [
    courseIDs.INTRODUCTION_TO_COMPUTER_SCIENCE,
    courseIDs.COMPUTER_SCIENCE_2,
    courseIDs.GAME_DEVELOPMENT_1,
    courseIDs.WEB_DEVELOPMENT_1,
    courseIDs.COMPUTER_SCIENCE_3,
    courseIDs.GAME_DEVELOPMENT_2,
    courseIDs.WEB_DEVELOPMENT_2,
    courseIDs.COMPUTER_SCIENCE_4,
    courseIDs.COMPUTER_SCIENCE_5,
  ];
  courses.sort((a, b) => {
    const aRank = orderedCourseIDs.indexOf(a) >= 0 ? orderedCourseIDs.indexOf(a) : 9000;
    const bRank = orderedCourseIDs.indexOf(b) >= 0 ? orderedCourseIDs.indexOf(b) : 9000;
    return aRank - bRank;
  });
}

function sortHeroCampaigns(campaigns) {
  const campaignIds = {
    DUNGEON: '549f07f7e21e041139ef28c7',
    GAME_DEVELOPMENT_1: '579fb6c7f380c444007e568d',
    WEB_DEVELOPMENT_1: '579fb6a6f380c444007e563a',
    FOREST: '549f0801e21e041139ef28c8',
    GAME_DEVELOPMENT_2: '579fb6c99872641f0080befa',
    WEB_DEVELOPMENT_2: '579fb6b6f380c444007e565c',
    DESERT: '549f080ae21e041139ef28c9',
    MOUNTAIN: '54b851b689b852a0b4d91037',
    GLACIER: '55721bff641c736e581a0a7c',
  };
  const orderedCampaignIds = [
    campaignIds.DUNGEON,
    campaignIds.GAME_DEVELOPMENT_1,
    campaignIds.WEB_DEVELOPMENT_1,
    campaignIds.FOREST,
    campaignIds.GAME_DEVELOPMENT_2,
    campaignIds.WEB_DEVELOPMENT_2,
    campaignIds.DESERT,
    campaignIds.MOUNTAIN,
    campaignIds.GLACIER,
  ];
  campaigns.sort((a, b) => {
    const aRank = orderedCampaignIds.indexOf(a) >= 0 ? orderedCampaignIds.indexOf(a) : 9000;
    const bRank = orderedCampaignIds.indexOf(b) >= 0 ? orderedCampaignIds.indexOf(b) : 9000;
    return aRank - bRank;
  });
}
