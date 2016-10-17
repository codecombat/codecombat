// Quick script to calculate how many students study more than one programming language, based on classroom settings

load('bower_components/lodash/dist/lodash.js');
userLanguagesMap = {};

// Construct map
db.classrooms.find().forEach(function(classroom) {
  if(!classroom.members) return;
  if(!(classroom.aceConfig && classroom.aceConfig.language)) return;
  var lang = classroom.aceConfig.language;
  classroom.members.forEach(function(memberID) {
    key = memberID + '';
    if(!userLanguagesMap[key]) userLanguagesMap[key] = [];
    userLanguagesMap[key].push(lang);
  })
});

// Count results
langCount = {}
Object.keys(userLanguagesMap).forEach(function(key) {
  langs = _.unique(userLanguagesMap[key]);
  countKey = langs.length.toString();
  if(!langCount[countKey]) langCount[countKey] = 0;
  langCount[countKey] += 1;
  if(langs.length > 2) {
    print('error: '+ JSON.stringify(userLanguagesMap[key]))
  }
});

print(JSON.stringify(langCount, null, '\t'));
