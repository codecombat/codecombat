// Finds all level guides for a particular campaign.

var campaignSlug = 'intro';
var campaign = db.campaigns.findOne({slug: campaignSlug});
var levelOriginals = Object.keys(campaign.levels);
levelOriginals.forEach(function(original) {
  var level = db.levels.findOne({original: ObjectId(original), slug: {$exists: true}});
  //print("found level", level);
  (level.documentation.specificArticles || []).forEach(function(doc) {
    if (doc.name != 'Overview') return;
    var exclusionRegex = new RegExp("```(clojure|lua|coffeescript|io)\n[^`]+```\n?", 'gm');
    var body = doc.body.replace(exclusionRegex, '');
    body = body.replace(/```python/g, '**Python**:\n```python');
    body = body.replace(/```javascript/g, '**JavaScript**:\n```javascript');
    print("\n\n## " + level.name + " Overview:\n\n" + body);
  });
});
