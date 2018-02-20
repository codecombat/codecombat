'use strict';
// Find our worst-performing levels recently-matches and warn about them on Slack.
// Look through a bunch of LevelSessions for mainstream users on weekdays, see what is bad and what has changed, notify about any we haven't notified recently.
// Comparing things like completion rates and completion times for home and classroom users to what we expect/care about for that kind of level.

if (process.argv.length !== 4) {
  console.log("Usage: node <script> <mongo connection Url> <mongo connection Url LevelSessions>");
  console.log("Include ?readPreference=secondary in connection URLs");
  process.exit();
}

require('coffee-script');
require('coffee-script/register');
const scriptStartTime = new Date();
const co = require('co');
const _ = require('lodash');
_.str = require('underscore.string')
_.mixin(_.str.exports())
const slack = require('../../server/slack');
const MongoClient = require('mongodb').MongoClient;
const mongoose = require('mongoose');
const mongoConnUrl = process.argv[2];
const mongoConnUrlLevelSessions = process.argv[3];

const debugOutput = true;
const daysToCheck = 7;  // Warn about completion problems arising in the past N days; should be a multiple of 7 to avoid weekend effects
//const daysBeforeRepeating = 7;  // Don't warn about this level if we would have warned in the past week
const daysBeforeRepeating = 0;  // First run
const maxProblemLevelsPerDay = 5;

const endDay = new Date(new Date().toISOString().substring(0, 10) + 'T00:00:00.000Z');
const endDayStr = endDay.toISOString().substring(0, 10)
let startDay = new Date(endDay);
startDay.setUTCDate(startDay.getUTCDate() - 2 * daysToCheck - daysBeforeRepeating - 1);
const startDayStr = startDay.toISOString().substring(0, 10)
debug(`Measuring days ${startDayStr} to ${endDayStr}; looking at last ${daysToCheck} days compared to past.`);

// TODO: cron this up

let prodDb, levelSessionsDb;

co(function*() {
  prodDb = yield MongoClient.connect(mongoConnUrl, {connectTimeoutMS: 1000 * 60 * 60, socketTimeoutMS: 1000 * 60 * 60});
  levelSessionsDb = yield MongoClient.connect(mongoConnUrlLevelSessions, {connectTimeoutMS: 1000 * 60 * 60, socketTimeoutMS: 1000 * 60 * 60});
  debug(`Connected to databases`);

  const startObjectId = objectIdWithTimestamp(startDay);
  const endObjectId = objectIdWithTimestamp(endDay);
  debug(`Finding LevelSessions created and changed between ${startDayStr} and ${endDayStr}...`);

  const query = {$and: [{_id: {$gte: startObjectId}}, {_id: {$lt: endObjectId}}]};
  const sessions = yield levelSessionsDb.collection('level.sessions').find(query, {creator: 1, 'stats.gamesCompleted': 1, playtime: 1, 'state.complete': 1, isForClassroom: 1, levelID: 1, heroConfig: 1, team: 1, codeLanguage: 1, created: 1}).toArray();
  debug(`Sessions found: ${sessions.length}`);

  const levelSessionMap = {};
  const userSessionMap = {};
  for (const session of sessions) {
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

  const levels = yield prodDb.collection('levels').find({slug: {$in: levelIDs}}, {slug: 1, type: 1, kind: 1, practice: 1, replayable: 1, assessment: 1, shareable: 1, adventurer: 1, adminOnly: 1, created: 1, requiresSubscription: 1}).toArray();
  const levelsBySlug = {};
  for (const level of levels) {
    if (level.adminOnly || level.replayable) continue;
    levelsBySlug[level.slug] = level;
  }
  debug(`... fetched ${levels.length} levels, kept ${Object.keys(levelsBySlug).length}`);

  const statsByLevel = {};
  const datesByIndex = [];
  const currentDay = startDay;
  const allProblemsByDay = [];
  const topProblemsByDay = [];
  while (currentDay < endDay) {
    for (const levelID of levelIDs) {
      const level = levelsBySlug[levelID];
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
    const userSessions = userSessionMap[user._id + ''];
    userSessions.sort((a, b) => a.created - b.created);
    for (const session of userSessions) {
      if (!session.playtime) continue;
      if (session.codeLanguage != 'python' && session.codeLanguage != 'javascript') continue;
      const level = levelsBySlug[session.levelID];
      if (!level) continue;
      const product = session.isForClassroom ? 'classroom' : 'home';
      let sessionStartIndex = 0;
      for (sessionStartIndex = datesByIndex.length - 1; datesByIndex[sessionStartIndex] > session.created; --sessionStartIndex) {}
      // TODO: ignore weekends, since those players are different from our main players?
      const stats = statsByLevel[session.levelID][product][session.codeLanguage][sessionStartIndex];
      ++stats.started;
      if (session.state && session.state.complete)
	++stats.completed;
      stats.playtime += session.playtime;
      // TODO: leftGame
    }
  }

  for (const levelID in statsByLevel) {
    for (const product in statsByLevel[levelID]) {
      for (const codeLanguage in statsByLevel[levelID][product]) {
        const statDays = statsByLevel[levelID][product][codeLanguage];
	for (let startDateIndex = 0; startDateIndex < datesByIndex.length - daysToCheck; ++startDateIndex) {
          const aggregateDateIndex = startDateIndex + daysToCheck;
          const aggregateStats = statsPlaceholder(datesByIndex[aggregateDateIndex]);
	  for (let dateIndex = startDateIndex; dateIndex < aggregateDateIndex; ++dateIndex) {
            const stats = statDays[dateIndex];
            aggregateStats.started += stats.started;
            aggregateStats.completed += stats.completed;
            aggregateStats.playtime += stats.playtime;
            aggregateStats.leftGame += stats.leftGame;
	  }
          const stats = statDays[aggregateDateIndex];
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
          const previousStats = statDays[dateIndex - daysToCheck];
	  const currentStats = statDays[dateIndex];
          const level = levelsBySlug[levelID];
          const problems = calculateProblems(level, product, codeLanguage, previousStats, currentStats);
          allProblemsByDay[dateIndex] = allProblemsByDay[dateIndex].concat(problems);
	}
      }
    }
  }
  //debug(JSON.stringify(statsByLevel, null, 2));

  for (let dateIndex = datesByIndex.length - daysToCheck; dateIndex < datesByIndex.length; ++dateIndex) {
    const previouslyWarnedTopProblemsByDay = topProblemsByDay.slice(Math.max(0, dateIndex - daysBeforeRepeating), dateIndex);
    topProblemsByDay[dateIndex] = filterTopProblems(allProblemsByDay[dateIndex], previouslyWarnedTopProblemsByDay);
  }
  //debug(JSON.stringify(topProblemsByDay, null, 2));
  logProblems(topProblemsByDay[datesByIndex.length - 1]);

  prodDb.close();
  levelSessionsDb.close();
  debug(`Script runtime: ${Math.round((new Date() - scriptStartTime) / 1000)}s`);
}).then(function (value) {
  
}, function (err) {
  console.error(err.stack);
  prodDb.close();
  levelSessionsDb.close();
  process.exit()
});

// Detect absolute problems with poorly performing levels
const levelThresholdsByType = {
  'hero': {completion: 0.9, playtime: 300, leftGame: 0.1},
  'course': {completion: 0.9, playtime: 300, leftGame: 0.1},
  'hero-ladder': {completion: 0.85, playtime: 450, leftGame: 0.1},
  'course-ladder': {completion: 0.8, playtime: 600, leftGame: 0.1},
  'game-dev': {completion: 0.9, playtime: 300, leftGame: 0.1},
  'web-dev': {completion: 0.9, playtime: 300, leftGame: 0.1},
}

function calculateProblems(level, product, codeLanguage, old, now) {
  const problems = [];
  if (now.aggregateStarted < 30 || old.aggregateStarted < 30) return problems;

  // Detect relative problems compared to last time window
  const nowCompletion = now.aggregateCompleted / now.aggregateStarted;
  const oldCompletion = old.aggregateCompleted / old.aggregateStarted;
  const nowFailureRate = 1 - nowCompletion;
  const oldFailureRate = 1 - oldCompletion;
  let severity, message;
  if (nowFailureRate > oldFailureRate * 1.25) {
    severity = (nowFailureRate - oldFailureRate) * Math.log(now.aggregateStarted);
    message = `${(nowCompletion * 100).toFixed(1)}% completion (was ${(oldCompletion * 100).toFixed(1)}%)`;
    problems.push({level, product, codeLanguage, old, now, severity, message, type: 'completion rate drop'});
  }

  const nowPlaytime = now.aggregatePlaytime / now.aggregateStarted;
  const oldPlaytime = old.aggregatePlaytime / old.aggregateStarted;
  if (nowPlaytime > oldPlaytime * 1.25) {
    severity = (nowPlaytime / oldPlaytime) * Math.log(now.aggregateStarted);
    message = `${nowPlaytime.toFixed(0)}s completion time (was ${oldPlaytime.toFixed(0)}s)`;
    problems.push({level, product, codeLanguage, old, now, severity, message, type: 'completion time increase'});
  }

  const nowLeftGame = now.aggregateLeftGame / now.aggregateStarted;
  const oldLeftGame = old.aggregateLeftGame / old.aggregateStarted;
  if (nowLeftGame > oldLeftGame * 1.25) {
    severity = (nowLeftGame / oldLeftGame) * Math.log(now.aggregateStarted);
    message = `${(nowLeftGame * 100).toFixed(1)}% left game (was ${(oldLeftGame * 100).toFixed(1)}%)`;
    problems.push({level, product, codeLanguage, old, now, severity, message, type: 'left game rate increase'});
  }

  // Detect absolute poor performance problems  
  const thresholds = levelThresholdsByType[level.type] || levelThresholdsByType.hero;
  let completionThreshold = thresholds.completion;
  let playtimeThreshold = thresholds.playtime;
  let leftGameThreshold = thresholds.leftGame;
  if (level.practice) {
    completionThreshold *= 0.8;
    playtimeThreshold *= 1.5;
    leftGameThreshold *= 1.5;
  }
  if (level.kind == 'mastery') {
    completionThreshold *= 0.9;
    playtimeThreshold *= 1.25;
    leftGameThreshold *= 1.25;
  }
  if (level.kind == 'advanced' || level.kind == 'challenge') {
    completionThreshold *= 0.7;
    playtimeThreshold *= 2;
    leftGameThreshold *= 2;
  }
  if (level.assessment) {
    completionThreshold *= 0.8;
    playtimeThreshold *= 1.5;
    leftGameThreshold *= 1.5;
  }
  if (level.shareable == 'project') {
    completionThreshold *= 0.8;
    playtimeThreshold *= 3;
    leftGameThreshold *= 1.5;
  }

  if (nowCompletion < completionThreshold) {
    severity = (nowFailureRate / (1 - completionThreshold)) * Math.log(now.aggregateStarted);
    message = `${(nowCompletion * 100).toFixed(1)}% completion (threshold: ${(completionThreshold * 100).toFixed(1)}%)`;
    problems.push({level, product, codeLanguage, old, now, severity, message, type: 'low completion rate'});
  }

  if (nowPlaytime > playtimeThreshold) {
    severity = (nowPlaytime / playtimeThreshold) * Math.log(now.aggregateStarted);
    message = `${nowPlaytime.toFixed(0)}s completion time (threshold ${playtimeThreshold.toFixed(0)}s)`;
    problems.push({level, product, codeLanguage, old, now, severity, message, type: 'high playtime'});
  }

  if (nowLeftGame > leftGameThreshold) {
    severity = (nowLeftGame / leftGameThreshold) * Math.log(now.aggregateStarted);
    message = `${(nowLeftGame * 100).toFixed(1)}% left game (threshold ${(leftGameThreshold * 100).toFixed(1)}%)`;
    problems.push({level, product, codeLanguage, old, now, severity, message, type: 'high left game rate'});
  }
  
  for (const problem of problems) {
    if (product == 'classroom')
      problem.severity *= 2;
  }

  return problems;
}

function filterTopProblems(problems, previouslyWarnedTopProblemsByDay) {
  // TODO: are we getting multiple days' problems in here sometimes?
  const previouslyWarnedTopProblemsByLevel = {};
  for (const problemsByDay of previouslyWarnedTopProblemsByDay) {
    for (const problem of problemsByDay) {
      previouslyWarnedTopProblemsByLevel[problem.level.slug] = (previouslyWarnedTopProblemsByLevel[problem.level.slug] || []).concat(problem);
    }
  }
  let topProblems = [];
  let problemLevelsCount = 0;
  problems.sort((a, b) => b.severity - a.severity);
  for (const problem of problems) {
    if (previouslyWarnedTopProblemsByLevel[problem.level.slug]) continue;
    if (topProblems.filter(p => p.level.slug == problem.level.slug).length) continue;  // Already did this level
    const thisLevelProblems = problems.filter(p => p.level.slug == problem.level.slug);
    topProblems = topProblems.concat(thisLevelProblems);
    if (++problemLevelsCount == maxProblemLevelsPerDay) break;
  }
  return topProblems;
}

function logProblems(problems) {
  const logLines = []
  logLines.push(`New problems for today (${new Date().toISOString().substring(0, 10)}):`);
  const problemsByLevel = _.groupBy(problems, (problem) => problem.level.slug);
  for (const levelID in problemsByLevel) {
    const problems = problemsByLevel[levelID];
    problems.sort((a, b) => b.severity - a.severity);
    logLines.push(`\t${levelID}, with ${problems[0].now.aggregateStarted} players in the past ${daysToCheck} days (${problems[0].old.aggregateStarted} in previous window):`);
    for (const problem of problems) {
      logLines.push(`\t  ${_.str.lpad(problem.severity.toFixed(1), 8)}  ${_.str.rpad(problem.product, 9)}  ${_.str.rpad(problem.codeLanguage, 10)}  ${_.str.rpad(problem.type, 20)}  ${problem.message}`);
    }
  }
  debug(logLines.join('\n'));
  slack.sendSlackMessage(`\`\`\`${logLines.join('\n')}\n\`\`\``, ['#game'], {markdown: true})
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
  const hexSeconds = Math.floor(timestamp/1000).toString(16);
  // Create an ObjectId with that hex timestamp
  const constructedObjectId = mongoose.Types.ObjectId(hexSeconds + "0000000000000000");
  return constructedObjectId;
}
