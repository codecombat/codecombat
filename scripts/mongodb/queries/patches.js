// Finds all patches and denorms their target names and creators.

var patches = db.patches.find({status:'pending'}).toArray();
for(var i in patches) {
  var patch = patches[i];
  var collection = null;
  if(patch.target.collection === 'level') collection = db.levels;
  if(patch.target.collection === 'level_component') collection = db.level.components;
  if(patch.target.collection === 'level_system') collection = db.level.systems;
  if(patch.target.collection === 'thang_type') collection = db.level.thang.types;
  if(collection === null) {
    print('could not find collection', patch.target.collection);
    continue;
  }
  var target = collection.findOne({original:patch.target.original, name:{$exists:true}});
  var creator = db.users.findOne({_id:patch.creator});
  if(target === null) {
    print('No target for patch from', patch.target.collection);
    continue;
  }
  if(creator === null) {
    print(target.name, 'made by unknown person...');
    continue;
  }
    
  print(target.name, 'made by', creator.name);
 }