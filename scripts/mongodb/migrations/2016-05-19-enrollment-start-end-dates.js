// Migrate users from coursePrepaidID to coursePrepaid

startDate = new Date(Date.UTC(2016,4,22)).toISOString(); // NOTE: Month is 0 indexed...
endDate = new Date(Date.UTC(2017,4,22)).toISOString();
print('Setting start/end', startDate, endDate);

db.prepaids.find({type: 'course'}).limit(10).forEach(function (prepaid) {
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
    print('updating prepaid', JSON.stringify(prepaid, null, '\t'));
    //print(db.prepaids.save(prepaid));
  }
  
  var redeemers = prepaid.redeemers || [];
  for (var index in redeemers) {
    var redeemer = redeemers[index];
    var user = db.users.findOne({ _id: redeemer.userID }, { coursePrepaid: 1, coursePrepaidID: 1 });
    if (user.coursePrepaidID && !user.coursePrepaid) {
      var update = {
        $set: { coursePrepaid: { _id: user.coursePrepaidID, startDate: prepaid.startDate, endDate: prepaid.endDate } },
        $unset: { coursePrepaidID: '' }
      }
      print('updating user', JSON.stringify(user, null, '  '), JSON.stringify(update, null, '  '));
      //print(db.users.update({_id: user._id}, update));
    }
  }
   
});
