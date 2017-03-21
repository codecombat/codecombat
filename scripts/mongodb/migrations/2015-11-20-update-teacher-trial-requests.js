// Set created field if necessary, and migrate previous teacher trial requests to database collection trial.requests

// Usage:
// mongo <address>:<port>/<database> <script file> -u <username> -p <password> --eval "var csvFilePath = '/Users/blah/Downloads/externalRequestData.csv'"

// NOTES
// Do not have prepaid IDs for these approved requests
// Do not have applicant user IDs
// Adding special properties.fromGoogleForm = true flag


if (typeof csvFilePath === 'undefined') {
  print("ERROR: no csvFilePath specified");
}
else {
  addCreated();
  insertExternalRequests();
}

function addCreated() {
  // Set created property if it's missing
  var cursor = db['trial.requests'].find({created: {$exists: false}});
  var updateCount = 0;
  while (cursor.hasNext()) {
    var doc = cursor.next();
    var writeResult = db['trial.requests'].update(
      {_id: doc._id},
      {$set: {created: doc._id.getTimestamp()}}
    );
    // printjson(writeResult);
    updateCount += writeResult.nModified;
    if (updateCount > 500) break;
  }
  print("Num created field added: ", updateCount);
}

function insertExternalRequests() {
  var file = cat(csvFilePath);
  var lines = file.split('\n');
  var lineRegExp = /(?!\s*$)\s*(?:'([^'\\]*(?:\\[\S\s][^'\\]*)*)'|"([^"\\]*(?:\\[\S\s][^"\\]*)*)"|([^,'"\s\\]*(?:\s+[^,'"\s\\]+)*))\s*(?:,|$)/g;
  updateCount = 0;
  for (var i = 1; i < lines.length; i++) {
      var matches = lines[i].match(lineRegExp);
      if (!matches || matches.length < 6) {
        print(i, lines[i]);
        continue;
      }

      // Instead of fixing the line regex
      for (var j = 0; j < matches.length; j++) {
        matches[j] = matches[j].substring(0, matches[j].length - 1);
        matches[j] = matches[j].replace(/"/ig, '');
      }

      // Build date
      var dateMatches = matches[0].split(/[\/: ]{1}/ig);
      if (!dateMatches || dateMatches.length !== 6) {
        print(matches[0], dateMatches.length);
        break;
      }

      var year = parseInt(dateMatches[2]);
      var month = parseInt(dateMatches[0]);
      var day = parseInt(dateMatches[1]);
      var hours = parseInt(dateMatches[3]);
      var minutes = parseInt(dateMatches[4]);
      var seconds = parseInt(dateMatches[5]);
      if (month < 10) month = "0" + month;
      if (day < 10) day = "0" + day;
      if (hours < 10) hours = "0" + hours;
      if (minutes < 10) minutes = "0" + minutes;
      if (seconds < 10) seconds = "0" + seconds;
      var isoDate = year + "-" + month + "-" + day + "T" + hours + ":" + minutes + ":" + seconds + ".000Z";
      var created = new Date(isoDate);
      // print(created.toISOString());

      var reviewDate = created;
      var reviewer = new ObjectId('52f94443fcb334581466a992');
      var properties = {
        heardAbout: matches[5],
        numStudents: matches[4],
        age: matches[3],
        location: matches[2],
        school: matches[2],
        email: matches[1],
        fromGoogleForm: true
      };
      var status = 'approved';
      var type = 'subscription';

      // print(created, reviewDate, reviewer, status, type);
      // printjson(properties);

      // Insert based on email
      writeResult = db['trial.requests'].update(
        {$and: [{'properties.fromGoogleForm': true}, {'properties.email': properties.email}]},
        {
          $set: {
            created: created,
            type: 'subscription',
            properties: properties,
            status: 'approved',
            reviewDate: reviewDate,
            reviewer: reviewer
          }
        },
        { upsert: true}
      );
      updateCount += writeResult.nModified + writeResult.nUpserted;
      if (updateCount >= 500) break;
  }
  print("Num external trial requests inserted:", updateCount);
}
