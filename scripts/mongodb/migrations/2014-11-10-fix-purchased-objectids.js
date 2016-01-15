var usersWithPurchases = db.users.find({"purchased.items": {$exists: true}}).toArray();
var itemsConverted = 0;
var usersConverted = 0;
for (var i = 0; i < usersWithPurchases.length; ++i) {
  var user = usersWithPurchases[i];
  var items = user.purchased.items;
  var convertThisUser = false;
  for (var j = 0; j < items.length; ++j) {
    var item = items[j];
    if (typeof item != 'string') {
      items[j] = '' + item;
      ++itemsConverted;
      convertThisUser = true;
    }
  }
  if (convertThisUser) {
    db.users.save(user);
    ++usersConverted;
 }
}
print("Had to convert", itemsConverted, "items and", usersConverted, "users");
