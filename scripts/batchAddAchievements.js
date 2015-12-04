fs = require('fs');
path = require('path');

GLOBAL._ = require('lodash')
_.string = require('underscore.string')

var tierNames = {
	"Wood":1,
	"Stone":2,
	"Silver":3,
	"Gold":4,
	"Diamond":5
}

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
	//0 is Category
	//5 is Title
	if(lines[i][0] == "Concept Mastery") {
		var a_name = "Completed " + lines[i][4] + " " + lines[i][1] + " Levels";
		var a_slug = _.string.slugify(a_name);
		console.log(a_slug);
		var a_description = lines[i - ((i - 3) % 5)][7].replace(/""/g, '"').replace(/\|/g, ",");
		var a_difficulty = parseInt(tierNames[lines[i][2]]);
		var a_worth = parseInt(lines[i][10]);
		var a_gems = parseInt(lines[i][11]);
		var a_queryName = "stats.concepts." + lines[i][1].toLowerCase().replace(/ /g, "_");
		var a_queryCount = parseInt(lines[i][4]);
		var achievement = {};
		//ID will be auto-assigned
		//achievement._id = "5659ca1b091b7a447bf095fe";
		achievement.slug = a_slug;
		achievement.i18nCoverage = [];
		achievement.i18n = {
			"-": {
				"-":"-"
			}
		};
		achievement.name = a_name;
		achievement.watchers = ["512ef4805a67a8c507000001"];
		//__v will be auto-assigned
		//achievement.__v = 0;
		achievement.collection = "users";
		achievement.description = a_description;
		achievement.difficulty = a_difficulty;
		achievement.query = {};
		achievement.query[a_queryName] = {
			"$gte":a_queryCount
		};
		achievement.rewards = {
			"gems":a_gems
		};
		achievement.userField = "_id";
		achievement.worth = a_worth;
		achievements.push(achievement);
	}
}

//Now you have access to an array (achievements) of Achievement objects 
