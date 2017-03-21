if ( typeof password === 'undefined' ) {
	throw "Please specify the coco user password on the commandline as --eval 'password \"<password>\"'";
}

if ( typeof _ === 'undefined' ) {
	throw "Please include underscore/lodash on the commandline before this script.";
}


var main = connect('ec2-52-4-223-77.compute-1.amazonaws.com:27017/coco', 'coco', password);
var ls = connect('ec2-54-236-64-198.compute-1.amazonaws.com:27017/coco', 'coco', password);
var users = main.users.find(
	{role: 'student', 
	//birthday: {$regex: /^20/}
	birthday: {$exists: 1}
	},
	{_id: 1, birthday: 1, email: 1}
).toArray();
print("Found " + users.length + " users in age range");

var names = {
	"5411cb3769152f1707be029c": "Dungeons of Kithgard",
	"54173c90844506ae0195a0b4": "Gems in the Deep",
	"54174347844506ae0195a0b8": "Shadow Guard",
	"54ca592de4983255055a5478": "Enemy Mine",
	"541875da4c16460000ab990f": "True Names",
	"5604169b60537b8705386a59": "Kithgard Librarian",
	"55ca293b9bc1892c835b0136": "Fire Dancing",
	"565ce2291b940587057366dd": "Loop Da Loop",
	"545a5914d820eb0000f6dc0a": "Haunted Kithmaze",
	"5418cf256bae62f707c7e1c3": "The Second Kithmaze",
	"5418d40f4c16460000ab9ac2": "Dread Door",
	"54e0cdefe308cb510555a7f5": "Cupboards of Kithgard",
	"54f0e074a375e47f055d619c": "Breakout",
	"5452adea57e83800009730ee": "Known Enemy",
	"5452c3ce57e83800009730f7": "Master of Names",
	"55ca29439bc1892c835b0137": "A Mayhem of Munchkins",
	"5452d8b906a59e000067e4fa": "The Gauntlet",
	"541b434e1ccc8eaae19f3c33": "The Final Kithmaze",
	"541c9a30c6362edfb0f34479": "Kithgard Gates",
	"5630eab0c0fcbd86057cc2f8": "Wakka Maul"
};

var samples = 0;
var excluded = 0;
var buckets = {
	30: 0,
	45: 0,
	60: 0,
	75: 0,
	90: 0,
	120: 0,
	'Infinity': 0
};

var years = {

};

_.shuffle(users.slice(0,1000)).forEach(function(user, idx) {
	print("Scan " + user.email + ' / ' + user.birthday);
	var totalPlayTime = 0;
	var sessions = ls.level.sessions.find(
		{code: {$exists: 1}, creator: user._id.valueOf()},
		{'created': 1, 'level': 1, playtime: 1, 'state.complete': 1}
	).toArray();
	sessions = _.sortBy(sessions, 'created');
	var success = false;
	for ( var i = 0; i < sessions.length; ++i ) {
		var s = sessions[i];
		var name = names[s.level.original];
		if ( !name ) {
			++excluded;
			return;
		}
		totalPlayTime += s.playtime;
		if ( name == 'Known Enemy' && s.state.complete ) {
			success = true;
			break;
		}
		
		//print(s.created, name, s.state.complete, totalPlayTime / 60);
	}
	if ( !success && totalPlayTime < 60 * 90 ) return;
	var by = ISODate(user.birthday).getYear();
	if ( !years[by] ) years[by] = 1;
	else ++years[by];
	++samples;
	if ( success ) {
		for ( var bracket in buckets ) {
			if ( Number(bracket) * 60 >= totalPlayTime ) {
				buckets[bracket]++;
			}
		}
	}
	//print(JSON.stringify(sessions, null, '  '));

});
print("Excluded " + excluded + "\tSample Size:" + samples );
_.forEach(buckets, function(v,k) {
	print(k + 'm\t', (v * 100 / samples) + '%');
});

//print(JSON.stringify(years, null, '  '));

