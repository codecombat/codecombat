'use strict';
// Find our worst-performing levels recently-matches and warn about them on Slack.
// Look through a bunch of LevelSessions for mainstream users on weekdays, see what is bad and what has changed, notify about any we haven't notified recently.
// Comparing things like completion rates and completion times for home and classroom users to what we expect/care about for that kind of level.

if (process.argv.length !== 4) {
  console.log("Usage: node <script> <mongo connection Url> <mongo connection Url LevelSessions>");
  console.log("Include ?readPreference=secondary in connection URLs");
  process.exit();
}

const scriptStartTime = new Date();
const co = require('co');
const MongoClient = require('mongodb').MongoClient;
const mongoose = require('mongoose');
const mongoConnUrl = process.argv[2];
const mongoConnUrlLevelSessions = process.argv[3];

const debugOutput = true;
const daysToCheck = 7;  // Warn about completion problems arising in the past N days; should be a multiple of 7 to avoid weekend effects
const daysBeforeRepeating = 7;  // Don't warn about this level if we would have warned in the past week
const maxProblemsPerDay = 5;

const endDay = new Date(new Date().toISOString().substring(0, 10) + 'T00:00:00.000Z');
const endDayStr = endDay.toISOString().substring(0, 10)
let startDay = new Date(endDay);
startDay.setUTCDate(startDay.getUTCDate() - 2 * daysToCheck - daysBeforeRepeating);
const startDayStr = startDay.toISOString().substring(0, 10)
debug(`Measuring days ${startDayStr} to ${endDayStr}; looking at last ${daysToCheck} days compared to past.`);

// TODO: cron this up

co(function*() {
  const prodDb = yield MongoClient.connect(mongoConnUrl, {connectTimeoutMS: 1000 * 60 * 60, socketTimeoutMS: 1000 * 60 * 60});
  const levelSessionsDb = yield MongoClient.connect(mongoConnUrlLevelSessions, {connectTimeoutMS: 1000 * 60 * 60, socketTimeoutMS: 1000 * 60 * 60});
  debug(`Connected to databases`);

  const startObjectId = objectIdWithTimestamp(startDay);
  const endObjectId = objectIdWithTimestamp(endDay);
  debug(`Finding LevelSessions created and changed between ${startDayStr} and ${endDayStr}...`);

  // TODO: find ways to make more performant if they take too long
  //let query = {$and: [{_id: {$gte: startObjectId}}, {_id: {$lt: endObjectId}}]};
  let query = {$and: [{_id: {$gte: startObjectId}}, {_id: {$lt: endObjectId}}, {levelID: {$in: ['cell-commentary', 'kithgard-gates', 'the-raised-sword', 'robot-ragnarok', 'signal-corpse']}}]};
  //let query = {$and: [{_id: {$gte: startObjectId}}, {_id: {$lt: endObjectId}}, {levelID: 'signal-corpse'}]};
  const sessions = yield levelSessionsDb.collection('level.sessions').find(query, {creator: 1, 'stats.gamesCompleted': 1, playtime: 1, 'state.complete': 1, isForClassroom: 1, levelID: 1, heroConfig: 1, team: 1, codeLanguage: 1, created: 1}).toArray();
  debug(`Sessions found: ${sessions.length}`);

  const levelSessionMap = {};
  const userSessionMap = {};
  for (let session of sessions) {
    if (!session.levelID) continue;
    if (!levelSessionMap[session.levelID]) levelSessionMap[session.levelID] = [];
    levelSessionMap[session.levelID].push(session);
    if (!userSessionMap[session.creator]) userSessionMap[session.creator] = [];
    userSessionMap[session.creator].push(session);
  }
  const levelIDs = Object.keys(levelSessionMap);
  const userIDs = Object.keys(userSessionMap);
  debug(`Unique users ${userIDs.length} over ${levelIDs.length} levels`);

  const userObjectIDs = userIDs.map((stringId) => mongoose.Types.ObjectId(stringId));
  const users = yield prodDb.collection('users').find({_id: {$in: userObjectIDs}}, {country: 1, role: 1, permissions: 1, stripe: 1, paypal: 1, anonymous: 1, preferredLanguage: 1, clientCreator: 1, createdOnHost: 1}).toArray();
  debug(`... fetched ${users.length} users`);

  const levels = yield prodDb.collection('levels').find({slug: {$in: levelIDs}}, {slug: 1, type: 1, kind: 1, practice: 1, replayable: 1, assessment: 1, adventurer: 1, adminOnly: 1, created: 1, requiresSubscription: 1}).toArray();
  let levelsBySlug = {};
  for (let level of levels) {
    if (level.adminOnly || level.replayable) continue;
    levelsBySlug[level.slug] = level;
  }
  debug(`... fetched ${levels.length} levels, kept ${Object.keys(levelsBySlug).length}`);

  let statsByLevel = {};
  let datesByIndex = [];
  let currentDay = startDay;
  let allProblemsByDay = [];
  let topProblemsByDay = [];
  while (currentDay < endDay) {
    for (const levelID of levelIDs) {
      let level = levelsBySlug[levelID];
      if (!level) continue;
      if (!statsByLevel[levelID]) statsByLevel[levelID] = {home: {javascript: [], python: []}, classroom: {javascript: [], python: []}};
      statsByLevel[levelID].home.javascript.push(statsPlaceholder(currentDay));
      statsByLevel[levelID].home.python.push(statsPlaceholder(currentDay));
      statsByLevel[levelID].classroom.javascript.push(statsPlaceholder(currentDay));
      statsByLevel[levelID].classroom.python.push(statsPlaceholder(currentDay));
    }
    datesByIndex.push(new Date(currentDay));
    currentDay.setUTCDate(currentDay.getUTCDate() + 1);
    allProblemsByDay.push([]);
    topProblemsByDay.push([]);
  }

  for (const user of users) {
    if (user.role && user.role != 'student') continue;  // No users who eventually became teachers
    if (user.permissions && (user.permissions.indexOf('admin') !== -1 || user.permissions.indexOf('artisan') !== -1 || user.permissions.indexOf('diplomat') !== -1)) continue;
    if (user.country && user.country != 'united-states') continue;  // TODO: upgrade to look at how different languages/countries are performing?
    if (user.preferredLanguage && user.preferredLanguage != 'en-US') continue;
    if (user.clientCreator) continue;
    let userSessions = userSessionMap[user._id + ''];
    userSessions.sort((a, b) => b.created - a.created);
    for (let session of userSessions) {
      if (!session.playtime) continue;
      if (session.codeLanguage != 'python' && session.codeLanguage != 'javascript') continue;
      let level = levelsBySlug[session.levelID];
      if (!level) continue;
      let product = session.isForClassroom ? 'classroom' : 'home';
      let sessionStartIndex = 0;
      for (sessionStartIndex = datesByIndex.length - 1; datesByIndex[sessionStartIndex] > session.created; --sessionStartIndex) {}
      // TODO: ignore weekends, since those players are different from our main players?
      let stats = statsByLevel[session.levelID][product][session.codeLanguage][sessionStartIndex];
      ++stats.started;
      if (session.state && session.state.complete)
	++stats.completed;
      stats.playtime += session.playtime;
      // TODO: leftGame
    }
  }

  for (let levelID in statsByLevel) {
    for (let product in statsByLevel[levelID]) {
      for (let codeLanguage in statsByLevel[levelID][product]) {
        let statDays = statsByLevel[levelID][product][codeLanguage];
	for (let startDateIndex = 0; startDateIndex < datesByIndex.length - daysToCheck; ++startDateIndex) {
          let aggregateDateIndex = startDateIndex + daysToCheck;
          let aggregateStats = statsPlaceholder(datesByIndex[aggregateDateIndex]);
          let dateIndex;
	  for (dateIndex = startDateIndex; dateIndex < aggregateDateIndex; ++dateIndex) {
            let stats = statDays[dateIndex];
            aggregateStats.started += stats.started;
            aggregateStats.completed += stats.completed;
            aggregateStats.playtime += stats.playtime;
            aggregateStats.leftGame += stats.leftGame;
	  }
          let stats = statDays[aggregateDateIndex];
          stats.aggregateStarted = aggregateStats.started;
          stats.aggregateCompleted = aggregateStats.completed;
          stats.aggregatePlaytime = aggregateStats.playtime;
          stats.aggregateLeftGame = aggregateStats.leftGame;
	}

	// Now that we have aggregated this stuff, we want to find the worst-performing levels.
	// MTWTFSSMTWTFSSMTWTFSS
	//                     ^  Currently Sunday
	//               ======+  Compare our daysToCheck window stats...
        //        ------+         ... to those from daysToCheck ago

	//              ======+   ... and then check windows within a range
        //       ------+          ... of daysBeforeRepeating to see whether

        // ...... more .........  ... we would have warned about this problem

	//        ======+         ... on a previous day,
        // ------+                ... and if so, skip the warning.

	for (let dateIndex = datesByIndex.length - daysToCheck; dateIndex < datesByIndex.length; ++dateIndex) {
          let previousStats = statDays[dateIndex - daysToCheck];
	  let currentStats = statDays[dateIndex];
          let problems = calculateProblems(levelID, product, codeLanguage, previousStats, currentStats);
          allProblemsByDay[dateIndex] = allProblemsByDay[dateIndex].concat(problems);
	}
      }
    }
  }
  //console.log(JSON.stringify(statsByLevel, null, 2));

  for (let dateIndex = datesByIndex.length - daysToCheck; dateIndex < datesByIndex.length; ++dateIndex) {
    let previouslyWarnedTopProblemsByDay = topProblemsByDay.slice(Math.max(0, dateIndex - daysBeforeRepeating), dateIndex);
    topProblemsByDay[dateIndex] = filterTopProblems(allProblemsByDay[dateIndex], previouslyWarnedTopProblemsByDay);
  }
  console.log(JSON.stringify(topProblemsByDay, null, 2));
  logProblems(topProblemsByDay[datesByIndex.length - 1]);

  prodDb.close();
  levelSessionsDb.close();
  debug(`Script runtime: ${new Date() - scriptStartTime}`);
})

function calculateProblems(levelID, product, codeLanguage, old, now) {
  let problems = [];
  if (now.aggregateStarted < 20 || old.aggregateStarted < 20) return problems;
  let nowCompletion = now.aggregateCompleted / now.aggregateStarted;
  let oldCompletion = old.aggregateCompleted / old.aggregateStarted;
  if ((1 - oldCompletion) / (1 - nowCompletion) < 0.8) {
    problems.push({levelID, product, codeLanguage, old, now, type: 'completion rate drop', oldCompletion, nowCompletion, severity: (oldCompletion - nowCompletion) * now.aggregateStarted});
  }
  // TODO: be able to detect more kinds of problems, of two main kinds: absolute problems, and new problems compared to past time period
  return problems;
}

function filterTopProblems(problems, previouslyWarnedTopProblemsByDay) {
  let previouslyWarnedTopProblemsByLevel = {};
  for (const problemsByDay of previouslyWarnedTopProblemsByDay) {
    for (const problem of problemsByDay) {
      previouslyWarnedTopProblemsByLevel[problem.levelID] = (previouslyWarnedTopProblemsByLevel[problem.levelID] || []).concat(problem);
    }
  }
  let topProblems = [];
  problems.sort((a, b) => a.severity - b.severity);
  for (let problem of problems) {
    if (previouslyWarnedTopProblemsByLevel[problem.levelID]) continue;
    if (topProblems.filter(p => p.levelID == problem.levelID).length) continue;  // Already did this level
    let thisLevelProblems = problems.filter(p => p.levelID == problem.levelID);
    topProblems = topProblems.concat(thisLevelProblems);
    if (topProblems.length == maxProblemsPerDay) break;
  }
  return topProblems;
}

function logProblems(problems) {
  debug('New problems for today:');
  for (let problem of problems) {
    console.log('\t\t' + JSON.stringify(problem));
  }
  // TODO: format these nicely
  // TODO: post to Slack
}

// * Helper functions

function statsPlaceholder(day) {
  return {
    day: day.toISOString().substring(0, 10),
    started: 0,
    completed: 0,
    playtime: 0,
    leftGame: 0,
  }
}

function debug(msg, ...args) {
  if (debugOutput) console.log(`${new Date().toISOString()} ${msg}`, ...args);
}

function objectIdWithTimestamp(timestamp) {
  // Convert string date to Date object (otherwise assume timestamp is a date)
  if (typeof(timestamp) == 'string') timestamp = new Date(timestamp);
  // Convert date object to hex seconds since Unix epoch
  let hexSeconds = Math.floor(timestamp/1000).toString(16);
  // Create an ObjectId with that hex timestamp
  let constructedObjectId = mongoose.Types.ObjectId(hexSeconds + "0000000000000000");
  return constructedObjectId;
}
