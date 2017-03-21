// Create 100 long-lasting licenses for a given user

// Usage
// ---------------
// In mongo shell
//
// > createLicenses('<user id string>');

var createLicenses = function updatePrepaid(userStringID) {
  try {
    var userID = ObjectId(userStringID);
  }
  catch (e) {
    print('Invalid ObjectId string given:', userStringID, e);
    return;
  }

  var user = db.users.findOne({_id: userID});
  if (!user) {
    print('User not found');
    return;
  }

  db.prepaids.save({
    redeemers: [],
    maxRedeemers: 100,
    startDate: "2000-01-01T00:00:00.000Z",
    endDate: "3000-01-01T00:00:00.000Z",
    type: 'course',
    creator: userID
  })
};
