require('coffee-script/register');
fs = require('fs');
path = require('path');

GLOBAL._ = require('lodash');
_.str = require('underscore.string');
_.mixin(_.str.exports());
GLOBAL.tv4 = require('tv4').tv4;

var database = require('../server/commons/database');
var mongoose = require('mongoose');

database.connect();

var Achievement = require('../server/models/Achievement');

var tierNames = {
  "Wood": 1,
  "Stone": 2,
  "Silver": 3,
  "Gold": 4,
  "Diamond": 5
};

file = fs.readFileSync('Code Combat New Achievements - Sheet1.csv', 'utf-8');
csvSplit = file.split(",");
var tLine = [];
var lines = [];
for(var cell in csvSplit) {
  tLine.push(csvSplit[cell]);
  if(csvSplit[cell].indexOf('\n') != -1) {
    lines.push(tLine);
    tLine = [];
  }
}

var achievements = [];

for(var i = 0; i < lines.length; i++) {
  // 0 is Category
  // 5 is Title
  if(lines[i][0] == "Concept Mastery") {
    var a_name = "Completed " + lines[i][4] + " " + lines[i][1] + " Levels";
    if (/Basic Syntax/.test(a_name)) continue;  // Already did these by hand
    var a_description = lines[i - ((i - 3) % 5)][7].replace(/""/g, '"').replace(/\|/g, ",");
    var a_difficulty = parseInt(tierNames[lines[i][2]]);
    var a_worth = parseInt(lines[i][10]);
    var a_gems = parseInt(lines[i][11]);
    var a_queryName = "stats.concepts." + lines[i][1].toLowerCase().replace(/ /g, "_");
    var a_queryCount = parseInt(lines[i][4]);
    var a_query = {};
    a_query[a_queryName] = {$gte: a_queryCount};
    var a_rewards = {gems: a_gems};

    var achievement = new Achievement({});
    achievement.set('name', a_name);
    achievement.set('i18n', {'-': {'-': '_'}});
    achievement.set('i18nCoverage', []);
    achievement.set('watchers', []);
    achievement.set('collection', 'users');
    achievement.set('userField', '_id');
    achievement.set('description', a_description);
    achievement.set('worth', a_worth);
    achievement.set('query', a_query);
    achievement.set('difficulty', a_difficulty);
    achievement.set('rewards', a_rewards);
    achievement.set('icon', 'db/achievement/53ed2e2bbbcf5c0000f8b6af/trophy.png');
    achievements.push(achievement);
    achievement.save(function(err) {});
}

// Now you have access to an array (achievements) of Achievement objects 
//console.log(JSON.stringify(achievements, null, 2));
