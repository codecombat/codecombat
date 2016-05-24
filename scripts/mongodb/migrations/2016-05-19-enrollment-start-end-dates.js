// Migrate users from coursePrepaidID to coursePrepaid

startDate = new Date(Date.UTC(2016,4,15)).toISOString(); // NOTE: Month is 0 indexed...
endDate = new Date(Date.UTC(2017,5,1)).toISOString();

cutoffDate = new Date(2015,11,11);
cutoffID = ObjectId(Math.floor(cutoffDate/1000).toString(16)+'0000000000000000');

print('Setting start/end', startDate, endDate, cutoffID);

var cursor = db.prepaids.find({type: 'course', _id: { $gt: cutoffID }})

cursor.forEach(function (prepaid) {
  var properties = prepaid.properties || {};
  if (!(prepaid.endDate && prepaid.startDate)) {
    if (!prepaid.endDate) {
      if(properties.endDate) {
        print('Updating from existing end date', properties.endDate);
        prepaid.endDate = properties.endDate.toISOString();
      }
      else {
        prepaid.endDate = endDate;
      }
    }
    if (!prepaid.startDate) {
      prepaid.startDate = startDate;
    }
    print('updating prepaid', prepaid._id, 'creator', prepaid.creator, 'start/end', prepaid.startDate, prepaid.endDate);
    print(' -', db.prepaids.save(prepaid));
  }
  
  var redeemers = prepaid.redeemers || [];
  for (var index in redeemers) {
    var redeemer = redeemers[index];
    var user = db.users.findOne({ _id: redeemer.userID }, { coursePrepaid: 1, coursePrepaidID: 1, email:1, name:1, permissions: 1 });
    if (user.coursePrepaidID && !user.coursePrepaid) {
      var update = {
        $set: { coursePrepaid: { _id: user.coursePrepaidID, startDate: prepaid.startDate, endDate: prepaid.endDate } },
        $unset: { coursePrepaidID: '' }
      }
      print('\t updating user', user._id, user.name, user.email, user.permissions, JSON.stringify(update));
      print('\t', db.users.update({_id: user._id}, update));
    }
  }
   
});
