// Usage: mongo <server>/coco -u <read-only-username> -p <read-only-password> what-unlocks-level.js
// Prints the slugs for levels that unlock the level given in findUnlocksForSlug

// CHANGE THIS to whatever level you want to find the unlocks for.
var findUnlocksForSlug = 'kithgard-apprentice';


var campaignSlugs = ['dungeon', 'forest', 'desert', 'mountain', 'glacier'];

print("Levels that unlock " + findUnlocksForSlug + ":");

var unlockLevel = db.levels.findOne({ slug: findUnlocksForSlug });
if(!unlockLevel) {
  print("Level " + findUnlocksForSlug + " not found.");
  quit();
}

var levelID = unlockLevel.original;
// print(levelID);

campaignSlugs.forEach(function(slug) {
  print("*** Searching " + slug + " ***");
  var campaign = db.campaigns.findOne({slug: slug });
  var levelOriginals = Object.keys(campaign.levels);

  //*** Each level in the campaign

  levelOriginals.some(function(original) {
    var level = campaign.levels[original];
    eachLevel(level);
    // this stops the .some() after one, for testing
    // return true;
  });

});

// ***** //

function eachLevel(level) {
  if(level.rewards) {
    for(var i=0; i < level.rewards.length; i++) {
      var reward = level.rewards[i];
      if(reward.level && reward.level == levelID) {
        var found = db.levels.findOne({original: ObjectId(level.original)});
        if(found.slug) {
          print(found.slug);
        } else {
          print("Found unlocking level, but it has no slug: " + JSON.stringify(reward.level));
        }
      }
    }
  }
}

