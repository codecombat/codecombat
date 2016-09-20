// Usage: Paste into mongodb client

VERSIONED_COLLECTIONS = {
  'article': db.articles,
  'level': db.levels,
  'level_component': db.level.components,
  'level_system': db.level.systems,
  'thang_type': db.thang.types
};

db.patches.find({created:{$gt: '2016-09-08'}}).forEach(function(patch) {
  if (!VERSIONED_COLLECTIONS[patch.target.collection]) {
    //print('skip', patch.target.collection);
    return;
  }
  if (patch.target.original && patch.target.id && patch.target.original.equals(patch.target.id)) {
    target = VERSIONED_COLLECTIONS[patch.target.collection].findOne({_id: patch.target.original});
    print('Update patch:',
      JSON.stringify({_id: patch._id}),
      JSON.stringify({$set: {'target.original': target.original}})
    );
    db.patches.update({_id: patch._id}, {$set: {'target.original': target.original}});
  }
  else {
    //print('They are different, they are fine');
  }
});
