var query = {
  birthday: {$exists: true},
  $where: 'this.birthday.length > 7',
  _id: { $gt: ObjectId('000000000000000000000000')}
};
while (true) {
  var users = db.users.find(query, {birthday:1}).limit(100).sort({_id:1}).toArray();
  if (users.length === 0) {
    break;
  } 
  users.forEach((user) => {
    print(user._id, user._id.getTimestamp());
    db.users.update({_id: user._id}, {$set:{birthday: user.birthday.slice(0,7)}})
  });
  query._id.$gt = users[users.length-1]._id
}
