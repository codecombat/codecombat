var scott = ObjectId('5162fab9c92b4c751e000274');
var nick = ObjectId('512ef4805a67a8c507000001');
//var collections = [db.levels, db.level.components, db.level.systems];
var collection = db.levels;
//var collection = db.level.components;
//var collection = db.level.systems;
var permission;

collection.find({slug:{$exists:1}}).forEach(function(doc) {
  print('--------------------------------------------------', doc.name);
  var official = false;
  var owner = null;
  var changed = false;
  for (var j in doc.permissions) {
    permission = doc.permissions[j];
    if(permission.access !== 'owner')
      continue;
    owner = permission.target;
    if(owner === scott+'') {
      print('Owner of', doc.name, 'is Scott');
      official = true;
    } 
    else if(owner === nick+'') {
      print('Owner of', doc.name, 'is Nick');
      official = true;
    }
    else {
      print('Owner of', doc.name, 'is', owner);
    }
  }
  if(!doc.watchers) {
    print('Init watchers, was', doc.watchers);
    doc.watchers = [];
  }
  if(official) {
    var hasNick = false;
    var hasScott = false;
    for(var k in doc.watchers) {
      var watcher = doc.watchers[k];
      if(watcher.equals(nick)) hasNick = true;
      if(watcher.equals(scott)) hasScott = true;
    }
    if(!hasNick) {
      doc.watchers.push(nick);
      print('Added Nick to', doc.name);
      changed = true;
    }
    if(!hasScott) {
      doc.watchers.push(scott);
      print('Added Scott to', doc.name);
      changed = true;
    }
  }
  else {
    var hasOwner = false;
    for(var l in doc.watchers) {
      var watcher = doc.watchers[l];
      if(watcher+'' === owner) hasOwner = true;
    }
    if(!hasOwner) {
      doc.watchers.push(ObjectId(owner));
      print('Added owner to', doc.name);
      changed = true;
    }
  }
  if(changed) {
    print('Changed, so saving');
    collection.save(doc);
  }
});