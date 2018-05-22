var query = {birthday: {$exists: true}, $where: 'this.birthday.length > 7'};
db.users.find(query, {birthday:1}).forEach((user) => {
  print(user._id);
  db.users.update({_id: user._id}, {$set:{birthday: user.birthday.slice(0,7)}})
});
