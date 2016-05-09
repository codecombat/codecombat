// Print out code language usage based on level session data

// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password>


var startDate = new Date();
startDate.setUTCDate(startDate.getUTCDate() - 7);
var startDay = startDate.toISOString(0, 10);

const endDate = new Date();
endDate.setUTCDate(endDate.getUTCDate());
var endDay = endDate.toISOString().substr(0, 10);

var startObj = objectIdWithTimestamp(ISODate(startDay + "T00:00:00.000Z"));
var endObj = objectIdWithTimestamp(ISODate(endDay + "T00:00:00.000Z"))

var query = {
  $and:[
    {_id:{$gte:startObj}},
    {_id:{$lt:endObj}}
  ]
}
var cursor = db.level.sessions.find(query, {playtime:1});
var count = 0;
var total = 0;

//Probably a built-in Mongo thing to do this... But it's not slow, so...
while(cursor.hasNext()) {
  result = cursor.next();
  if(result.playtime >= 60 * 10) {
    count++;
  }
  total++;
}

print("Number of sessions equal or over 60 * 10 playtime over the past 7 days: " + count + "\n" + "Total number of sessions over the past 7 days: " + total);

function objectIdWithTimestamp(timestamp) {
  // Convert string date to Date object (otherwise assume timestamp is a date)
  if (typeof(timestamp) == 'string') timestamp = new Date(timestamp);
  // Convert date object to hex seconds since Unix epoch
  const hexSeconds = Math.floor(timestamp/1000).toString(16);
  // Create an ObjectId with that hex timestamp
  const constructedObjectId = ObjectId(hexSeconds + "0000000000000000");
  return constructedObjectId
}