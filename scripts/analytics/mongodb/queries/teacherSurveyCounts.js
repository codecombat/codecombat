 // Print out teacher survey counts by day

// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>

var days = [];
var currentDay = '2016-01-01';
while (currentDay < '2017-01-01') {
  days.push(currentDay.substring(5));
  var d = new Date(currentDay);
  d.setUTCDate(d.getUTCDate() + 1);
  currentDay = d.toISOString().substring(0, 10);
}

var surveyDayMap = {};
var cursor = db['trial.requests'].find();
while (cursor.hasNext()) {
  var doc = cursor.next();
  var date = doc._id.getTimestamp();
  if (doc.created) {
    date = doc.created;
  }
  var day = date.toISOString().substring(0, 10);
  if (!surveyDayMap[day]) surveyDayMap[day] = 0;
  surveyDayMap[day]++;
}

print('day,2015,2016,2017');
for (var i = 0; i < days.length; i++) {
  var day = days[i];
  var c15 = surveyDayMap['2015-' + day] || 0;
  var c16 = surveyDayMap['2016-' + day] || 0;
  var c17 = surveyDayMap['2017-' + day] || 0;
  print(day + ',' + c15 + ',' + c16 + ',' + c17);
}

// var surveysSorted = [];
// for (var day in surveyDayMap) {
//   surveysSorted.push({day: day, count: surveyDayMap[day]});
// }
// surveysSorted.sort(function(a, b) {return a.day.localeCompare(b.day);});
// print("Number of teacher surveys per day:")

// var startDay = '2015-01-01';
// for (var i = 0; i < surveysSorted.length; i++) {
//   var stars = new Array(surveysSorted[i].count + 1).join('*');
//   // print(surveysSorted[i].day + "\t" + surveysSorted[i].count + "\t" + stars);
//   print(surveysSorted[i].day + "," + surveysSorted[i].count);
// }
