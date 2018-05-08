'use strict';
// Find our worst-performing levels recently-matches and warn about them on Slack.
// Look through a bunch of LevelSessions for mainstream users on weekdays, see what is bad and what has changed, notify about any we haven't notified recently.
// Comparing things like completion rates and completion times for home and classroom users to what we expect/care about for that kind of level.

if (process.argv.length !== 4) {
  console.log("Usage: node --max-old-space-size=8192 <script> <mongo connection Url> <mongo connection Url LevelSessions>");
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
const daysToCheck = 2 * 7;  // Warn about completion problems arising in the past N days; should be a multiple of 7 to avoid weekend effects
//const daysBeforeRepeating = 7;  // Don't warn about this level if we would have warned in the past week
const daysBeforeRepeating = 0;  // First run
const daysBeforeCountingLeftGame = 7;
const maxProblemLevelsPerDay = 10;
const maxRecoveryLevelsPerDay = Math.round(maxProblemLevelsPerDay / 2);
const minPlayersPerRelativeProblem = 70;
const minPlayersPerAbsoluteProblem = 35;

const endDay = new Date(new Date().toISOString().substring(0, 10) + 'T00:00:00.000Z');
endDay.setUTCDate(endDay.getUTCDate() - 1);  // Give people at least a day to finish levels they started
const dayBeforeEndDay = new Date(endDay);
dayBeforeEndDay.setUTCDate(endDay.getUTCDate() - 1);  // When reporting, report end-date as if it's an inclusive range
const endDayStr = dayBeforeEndDay.toISOString().substring(0, 10);
let startDay = new Date(endDay);
startDay.setUTCDate(startDay.getUTCDate() - 2 * daysToCheck - 1);
const startDayStr = startDay.toISOString().substring(0, 10)
debug(`Measuring sessions between start of ${startDayStr} and end of ${endDayStr}; looking at last ${daysToCheck} days compared to past.`);

let prodDb, levelSessionsDb;
const statsByLevel = {};

co(function*() {
  prodDb = yield MongoClient.connect(mongoConnUrl, {connectTimeoutMS: 1000 * 60 * 60, socketTimeoutMS: 1000 * 60 * 60});
  levelSessionsDb = yield MongoClient.connect(mongoConnUrlLevelSessions, {connectTimeoutMS: 1000 * 60 * 60, socketTimeoutMS: 1000 * 60 * 60});
  debug(`Connected to databases`);

  const startObjectId = objectIdWithTimestamp(startDay);
  const endObjectId = objectIdWithTimestamp(endDay);
  debug(`Finding LevelSessions created since start of ${startDayStr}...`);

  const query = {_id: {$gte: startObjectId}};
  const sessions = yield levelSessionsDb.collection('level.sessions').find(query, {creator: 1, 'stats.gamesCompleted': 1, playtime: 1, 'state.complete': 1, isForClassroom: 1, levelID: 1, heroConfig: 1, team: 1, codeLanguage: 1, created: 1, changed: 1}).toArray();
  debug(`... fetched ${sessions.length} sessions`);

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
  debug(`Fetching ${userIDs.length} unique users over ${levelIDs.length} levels`);

  const userObjectIDs = userIDs.map((stringId) => mongoose.Types.ObjectId(stringId));
  const users = yield prodDb.collection('users').find({_id: {$in: userObjectIDs}}, {country: 1, role: 1, permissions: 1, stripe: 1, paypal: 1, anonymous: 1, preferredLanguage: 1, clientCreator: 1, createdOnHost: 1, hourOfCode: 1}).toArray();
  debug(`... fetched ${users.length} users`);

  const campaigns = yield prodDb.collection('campaigns').find({slug: {$exists: true}}, {slug: 1, levels: 1}).toArray();
  debug(`... fetched ${campaigns.length} campaigns`);

  const levels = yield prodDb.collection('levels').find({slug: {$in: levelIDs}}, {slug: 1, type: 1, kind: 1, practice: 1, replayable: 1, assessment: 1, shareable: 1, adventurer: 1, adminOnly: 1, created: 1, requiresSubscription: 1, original: 1}).toArray();
  const levelsBySlug = {};
  for (const level of levels) {
    if (level.adminOnly || level.replayable) continue;
    levelsBySlug[level.slug] = level;
    for (const campaign of campaigns) {
      if (campaign.levels[level.original]) {
        level.campaignSlug = campaign.slug;
        break;
      }
    }
  }
  debug(`... fetched ${levels.length} levels, kept ${Object.keys(levelsBySlug).length}`);

  const datesByIndex = [];
  const currentDay = startDay;
  const allProblemsByDay = [];
  const topProblemsByDay = [];
  while (currentDay < endDay) {
    for (const levelID of levelIDs) {
      const level = levelsBySlug[levelID];
      if (!level) continue;
      if (!statsByLevel[levelID]) statsByLevel[levelID] = {home: {javascript: [], python: []}, classroom: {javascript: [], python: []}};
      statsByLevel[levelID].classroom.python.push(statsPlaceholder(currentDay));
      statsByLevel[levelID].classroom.javascript.push(statsPlaceholder(currentDay));
      statsByLevel[levelID].home.python.push(statsPlaceholder(currentDay));
      statsByLevel[levelID].home.javascript.push(statsPlaceholder(currentDay));
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
    userSessions.sort((a, b) => a.changed - b.changed);
    const lastChangedSession = _.last(userSessions);
    userSessions.sort((a, b) => a.created - b.created);
    const lastCreatedSession = _.last(userSessions);
    for (const session of userSessions) {
      if (session.created > endDay) continue;
      if (!session.playtime) continue;
      if (session.codeLanguage != 'python' && session.codeLanguage != 'javascript') continue;
      const level = levelsBySlug[session.levelID];
      if (!level) continue;
      if (level.requiresSubscription && user.anonymous) continue;  // game-dev-hoc anonymous HoC players are a lost cause; TODO: include even registered HoC players
      const product = session.isForClassroom ? 'classroom' : 'home';
      let sessionStartIndex = 0;
      for (sessionStartIndex = datesByIndex.length - 1; datesByIndex[sessionStartIndex] > session.created; --sessionStartIndex) {}
      const stats = statsByLevel[session.levelID][product][session.codeLanguage][sessionStartIndex];
      ++stats.started;
      if (session.state && session.state.complete)
        ++stats.completed;
      // Playtime: check for outliers (bugs in AFK detection, or maybe student changed system time during level)
      const averagePlaytimeSoFar = (stats.playtime || 30 * 60) / (stats.started || 1);
      if (session.playtime > 5 * 60 * 60 ||
          (stats.started > 25 && session.playtime > Math.max(2 * 60 * 60, 40 * averagePlaytimeSoFar)))
        session.playtime = 5 * averagePlaytimeSoFar;
      stats.playtime += session.playtime;
      if (session == lastCreatedSession && session == lastChangedSession) {
        if (new Date() - session.changed > daysBeforeCountingLeftGame * 86400 * 1000)
          ++stats.leftGame;
        else
          ++stats.mightLeaveGame;
      }
      else
        ++stats.continuedGame;
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
            aggregateStats.mightLeaveGame += stats.mightLeaveGame;
            aggregateStats.continuedGame += stats.continuedGame;
          }
          const stats = statDays[aggregateDateIndex];
          stats.aggregateStarted = aggregateStats.started;
          stats.aggregateCompleted = aggregateStats.completed;
          stats.aggregatePlaytime = aggregateStats.playtime;
          stats.aggregateLeftGame = aggregateStats.leftGame;
          stats.aggregateMightLeaveGame = aggregateStats.mightLeaveGame;
          stats.aggregateContinuedGame = aggregateStats.continuedGame;
        }

        // Now that we have aggregated this stuff, we want to find the worst-performing levels.
        // SMTWTFSSMTWTFSSM
        //              ^.. Currently Monday morning, so we start on Saturday (giving Sunday's players a day to finish)
        //        ======+   Compare our daysToCheck window stats...
        // ------+          ... to those from daysToCheck ago
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
    // First approach won't work; have to log the problems we did warn about somehow, then read that log here.
    //const previouslyWarnedTopProblemsByDay = topProblemsByDay.slice(Math.max(0, dateIndex - daysBeforeRepeating), dateIndex);
    const previouslyWarnedTopProblemsByDay = [];
    topProblemsByDay[dateIndex] = filterTopProblems(allProblemsByDay[dateIndex], previouslyWarnedTopProblemsByDay);
  }
  //debug(JSON.stringify(topProblemsByDay, null, 2));

  logProblems(topProblemsByDay[datesByIndex.length - 1]);

  prodDb.close();
  levelSessionsDb.close();
  debug(`Script runtime: ${Math.round((new Date() - scriptStartTime) / 1000)}s`);
}).then(function (value) {}, function (err) {
  console.error(err.stack);
  prodDb.close();
  levelSessionsDb.close();
  process.exit()
});


const levelThresholdsByType = {
  'hero': {completion: 0.9, playtime: 300, playtimeMin: 60, leftGame: 0.1},
  'course': {completion: 0.9, playtime: 300, playtimeMin: 60, leftGame: 0.1},
  'hero-ladder': {completion: 0.85, playtime: 450, playtimeMin: 120, leftGame: 0.1},
  'course-ladder': {completion: 0.8, playtime: 600, playtimeMin: 120, leftGame: 0.1},
  'game-dev': {completion: 0.9, playtime: 300, playtimeMin: 30, leftGame: 0.1},
  'web-dev': {completion: 0.9, playtime: 300, playtimeMin: 30, leftGame: 0.1},
}

function calculateProblems(level, product, codeLanguage, old, now) {
  const problems = [];
  if (now.aggregateStarted < minPlayersPerAbsoluteProblem) return problems;

  const thresholds = levelThresholdsByType[level.type] || levelThresholdsByType.hero;
  let completionThreshold = thresholds.completion;
  let playtimeThreshold = thresholds.playtime;
  let playtimeThresholdMin = thresholds.playtimeMin;
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
    playtimeThreshold *= 24;
    leftGameThreshold *= 1.5;
  }
  if (level.slug == 'wakka-maul') {
    leftGameThreshold = 1;
  }

  // Detect relative problems compared to last time window
  const nowCompletion = now.aggregateCompleted / now.aggregateStarted;
  const oldCompletion = old.aggregateCompleted / old.aggregateStarted;
  const nowFailureRate = 1 - nowCompletion;
  const oldFailureRate = 1 - oldCompletion;
  const nowPlaytime = now.aggregatePlaytime / now.aggregateStarted;
  const oldPlaytime = old.aggregatePlaytime / old.aggregateStarted;
  const nowLeftGameDenominator = (now.aggregateLeftGame + now.aggregateContinuedGame)
  const oldLeftGameDenominator = (old.aggregateLeftGame + old.aggregateContinuedGame)
  const nowLeftGame = now.aggregateLeftGame / nowLeftGameDenominator;
  const oldLeftGame = old.aggregateLeftGame / oldLeftGameDenominator;
  let severity, message;
  if (now.aggregateStarted >= minPlayersPerRelativeProblem && old.aggregateStarted >= minPlayersPerRelativeProblem) {
    if (nowFailureRate > oldFailureRate * 1.25 && nowCompletion < completionThreshold) {
      severity = ((nowFailureRate - oldFailureRate) / Math.max(0.03, oldFailureRate)) * Math.log(now.aggregateStarted);
      message = `${(nowCompletion * 100).toFixed(1)}% completion (was ${(oldCompletion * 100).toFixed(1)}%)`;
      problems.push({level, product, codeLanguage, old, now, severity, message, type: 'completion rate drop'});
    }
    if (nowFailureRate < oldFailureRate / 1.25 && oldCompletion < completionThreshold) {
      severity = ((nowFailureRate - oldFailureRate) / Math.max(0.03, oldFailureRate)) * Math.log(now.aggregateStarted);
      message = `${(nowCompletion * 100).toFixed(1)}% completion (was ${(oldCompletion * 100).toFixed(1)}%)`;
      problems.push({level, product, codeLanguage, old, now, severity, message, type: 'completion rate increase'});
    }

    if (nowPlaytime > oldPlaytime * 1.25 && nowPlaytime > playtimeThreshold) {
      severity = ((nowPlaytime - oldPlaytime) / oldPlaytime) * Math.log(now.aggregateStarted);
      message = `${nowPlaytime.toFixed(0)}s completion time (was ${oldPlaytime.toFixed(0)}s)`;
      problems.push({level, product, codeLanguage, old, now, severity, message, type: 'completion time increase'});
    }
    if (nowPlaytime < oldPlaytime / 1.25 && oldPlaytime > playtimeThreshold) {
      severity = ((nowPlaytime - oldPlaytime) / oldPlaytime) * Math.log(now.aggregateStarted) / 2;
      message = `${nowPlaytime.toFixed(0)}s completion time (was ${oldPlaytime.toFixed(0)}s)`;
      problems.push({level, product, codeLanguage, old, now, severity, message, type: 'completion time decrease'});
    }

    if (nowLeftGameDenominator >= minPlayersPerRelativeProblem && oldLeftGameDenominator >= minPlayersPerRelativeProblem) {
      if (nowLeftGame > oldLeftGame * 1.25 && nowLeftGame > leftGameThreshold) {
        severity = ((nowLeftGame - oldLeftGame) / Math.max(0.03, oldLeftGame)) * Math.log(nowLeftGameDenominator);
        message = `${(nowLeftGame * 100).toFixed(1)}% left game (was ${(oldLeftGame * 100).toFixed(1)}%)`;
        problems.push({level, product, codeLanguage, old, now, severity, message, type: 'left game rate increase'});
      }
      if (nowLeftGame < oldLeftGame / 1.25 && oldLeftGame > leftGameThreshold) {
        severity = ((nowLeftGame - oldLeftGame) / Math.max(0.03, oldLeftGame)) * Math.log(nowLeftGameDenominator) / 2;
        message = `${(nowLeftGame * 100).toFixed(1)}% left game (was ${(oldLeftGame * 100).toFixed(1)}%)`;
        problems.push({level, product, codeLanguage, old, now, severity, message, type: 'left game rate decrease'});
      }
    }
  }

  // Detect absolute poor performance problems
  if (nowCompletion < completionThreshold) {
    const failureThreshold = (1 - completionThreshold)
    severity = ((nowFailureRate - failureThreshold) / failureThreshold) * Math.log(now.aggregateStarted);
    message = `${(nowCompletion * 100).toFixed(1)}% completion (threshold: ${(completionThreshold * 100).toFixed(1)}%)`;
    problems.push({level, product, codeLanguage, old, now, severity, message, type: 'low completion rate'});
  }

  if (nowPlaytime > playtimeThreshold) {
    severity = ((nowPlaytime - playtimeThreshold) / playtimeThreshold) * Math.log(now.aggregateStarted);
    message = `${nowPlaytime.toFixed(0)}s completion time (threshold ${playtimeThreshold.toFixed(0)}s)`;
    problems.push({level, product, codeLanguage, old, now, severity, message, type: 'high playtime'});
  }

  if (nowPlaytime < playtimeThresholdMin) {
    severity = ((playtimeThresholdMin - nowPlaytime) / playtimeThresholdMin) * Math.log(now.aggregateStarted);
    message = `${nowPlaytime.toFixed(0)}s completion time (threshold ${playtimeThresholdMin.toFixed(0)}s)`;
    problems.push({level, product, codeLanguage, old, now, severity, message, type: 'low playtime'});
  }

  if (nowLeftGame > leftGameThreshold && nowLeftGameDenominator >= minPlayersPerAbsoluteProblem) {
    severity = ((nowLeftGame - leftGameThreshold) / leftGameThreshold) * Math.log(nowLeftGameDenominator) * 1.5;
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
  let recoveryLevelsCount = 0;
  problems.sort((a, b) => a.severity - b.severity);
  for (const problem of problems) {
    if (previouslyWarnedTopProblemsByLevel[problem.level.slug]) continue;
    if (topProblems.filter(p => p.level.slug == problem.level.slug).length) continue;  // Already did this level
    if (problem.severity >= -4) continue;  // Not a good thing to call out, or not good enough
    const thisLevelProblems = problems.filter(p => p.level.slug == problem.level.slug && p.severity <= -0.1);
    topProblems = topProblems.concat(thisLevelProblems);
    if (++recoveryLevelsCount == maxRecoveryLevelsPerDay) break;
  }
  return topProblems;
}

function logProblems(problems) {
  const problemsByLevel = _.groupBy(problems, (problem) => problem.level.slug);
  let messagesSent = 0;
  const slackMessages = [];
  for (const levelID in problemsByLevel) {
    const problems = problemsByLevel[levelID];
    problems.sort((a, b) => b.severity - a.severity);
    const recovery = problems[0].severity < 0;
    let logLines = describeLevel(problems[0].level, messagesSent++, recovery);
    for (const problem of problems) {
      if ((problem.severity > 0 && problem.severity >= 0.1 * problems[0].severity) || (problem.severity < 0 && recovery))
        logLines.push(`Severity ${_.str.lpad(problem.severity.toFixed(1), 5)}: ${_.str.lpad(problem.now.aggregateStarted, 5)}  ${_.str.rpad(problem.product, 9)}  ${_.str.rpad(problem.codeLanguage, 10)}  ${_.str.rpad(problem.type, 20)}  ${problem.message}`);
    }
    console.log(logLines.join('\n'));
    slackMessages.push(`${logLines[0]}\n\`\`\`${logLines.slice(1).join('\n')}\n\`\`\``);
  }
  for (let messageIndex = 0; messageIndex < slackMessages.length; ++messageIndex) {
    const sendIt = function(message) { return function() { slack.sendSlackMessage(message, ['#game'], {markdown: true, forceSend: true, quiet: true}); } };
    setTimeout(sendIt(slackMessages[messageIndex]), messageIndex * 1000);
  }
}

function describeLevel(level, messagesSent, recovery) {
  const thisLevelStats = statsByLevel[level.slug];
  const logLines = [];
  let nowPlayers = 0, oldPlayers = 0;
  for (const product of ['classroom', 'home']) {
    for (const codeLanguage of ['python', 'javascript']) {
      const statsByDay = thisLevelStats[product][codeLanguage];
      const stats = _.last(statsByDay);
      if (!stats.aggregateStarted) continue;
      let playerCountDisplay = _.str.lpad(stats.aggregateStarted, 5);
      if (stats.aggregateStarted < minPlayersPerAbsoluteProblem)
        playerCountDisplay = '*' + _.str.lpad(stats.aggregateStarted, 4);
      logLines.push(`${playerCountDisplay} ${_.str.rpad(product, 9)} ${_.str.rpad(codeLanguage, 10)} players with ${_.str.lpad(((stats.aggregateCompleted / stats.aggregateStarted) * 100).toFixed(1), 5)}% completion, ${_.str.lpad((stats.aggregatePlaytime / stats.aggregateStarted).toFixed(0), 4)}s playtime, ${_.str.lpad(((stats.aggregateLeftGame / (stats.aggregateLeftGame + stats.aggregateContinuedGame)) * 100).toFixed(1), 5)}% left game`);
      nowPlayers += stats.aggregateStarted;
      oldPlayers += statsByDay[statsByDay.length - 1 - daysToCheck].aggregateStarted;
    }
  }
  logLines.unshift(`*${messagesSent + 1}. ${endDayStr} ${level.slug}*${recovery ? ' (recovery)' : ''}, with ${nowPlayers} players in the past ${daysToCheck} days (${oldPlayers} in previous window) - https://direct.codecombat.com/editor/level/${level.slug} - https://direct.codecombat.com/editor/campaign/${level.campaignSlug}#${level.slug}`);
  return logLines;
}

function statsPlaceholder(day) {
  return {
    day: day.toISOString().substring(0, 10),
    started: 0,
    completed: 0,
    playtime: 0,
    leftGame: 0,
    mightLeaveGame: 0,
    continuedGame: 0,
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
