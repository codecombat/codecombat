 // Print out teacher survey counts by day

// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>

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

var surveysSorted = [];
for (var day in surveyDayMap) {
  surveysSorted.push({day: day, count: surveyDayMap[day]});
}
surveysSorted.sort(function(a, b) {return a.day.localeCompare(b.day);});
print("Number of teacher surveys per day:")
for (var i = 0; i < surveysSorted.length; i++) {
  var stars = new Array(surveysSorted[i].count + 1).join('*');
  print(surveysSorted[i].day + "\t" + surveysSorted[i].count + "\t" + stars);
}
