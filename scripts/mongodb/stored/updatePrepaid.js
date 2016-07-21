
// Update a prepaid document, and the denormalized data on user documents
// Limits the properties allowed to be set, but does not perform validation on them. Use carefully!

// Usage
// ---------------
// In mongo shell
//
// > db.loadServerScripts();
// > updatePrepaid('<prepaid id string>', { endDate: "2017-07-01T00:00:00.000Z", maxRedeemers: 10 });

var updatePrepaid = function updatePrepaid(stringID, originalUpdate) {
  try {
    load('./bower_components/lodash/dist/lodash.js')
  }
  catch (e) {
    print('Lodash could not be loaded, ensure you are in codecombat project directory.')
    return;
  }
  
  try {
    var id = ObjectId(stringID);
  }
  catch (e) {
    print('Invalid ObjectId given:', stringID);
    return;
  }

  var prepaid = db.prepaids.findOne({_id: id});
  if (!prepaid) {
    print('Prepaid not found');
    return;
  }

  print('Found prepaid', JSON.stringify(_.omit(prepaid, 'redeemers'), null, '  '));
  print('-- has', prepaid.redeemers.length, 'redeemers.');

  var prepaidUpdate = _.pick(originalUpdate, 'maxRedeemers', 'startDate', 'endDate' );
  if (_.isEmpty(prepaidUpdate)) {
    print('\nSkipping prepaid update, nothing to update.')
  }
  else {
    print('\nUpdate prepaid',
      JSON.stringify(prepaidUpdate, null, '  '),
      db.prepaids.update(
        {_id: id},
        { $set: prepaidUpdate }
      )
    )
  }
  
  var userUpdate = _.pick(originalUpdate, 'startDate', 'endDate' );
  if (_.isEmpty(userUpdate)) {
    print('\nSkipping user update, nothing to update.')
  }
  else {
    print('\nUpdate users', 
      JSON.stringify(userUpdate, null, '  '), 
      db.users.update(
        {'coursePrepaid._id': id},
        {$set: userUpdate}, 
        {multi: true}
      )
    );
  }
};

db.system.js.save(
  {
    _id: 'updatePrepaid',
    value: updatePrepaid
  }
);
