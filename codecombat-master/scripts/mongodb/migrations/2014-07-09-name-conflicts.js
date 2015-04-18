load('bower_components/lodash/dist/lodash.js');
load('bower_components/underscore.string/dist/underscore.string.min.js');

var slugs = {};
var num = 0;

var unconflictName;

unconflictName = function(name) {
  var otherUser, suffix;
  otherUser = db.users.findOne({
    slug: _.string.slugify(name)
  });
  if (!otherUser) {
    return name;
  }
  suffix = _.random(0, 9) + '';
  return unconflictName(name + suffix);
};

var params = {
  name:1,
  emails:1,
  email:1,
  slug:1,
  dateCreated:1
};

db.users.find({anonymous:false}, params).sort({_id:1}).forEach(function (user) {
  num += 1;
  var slug = _.string.slugify(user.name);
  if(!slug) return;
  var update = {};
  if(slugs[slug]) {
    originalName = slugs[slug];
    conflictingName = user.name;
    availableName = unconflictName(conflictingName);
    conflictingSlug = slug;
    slug = _.string.slugify(availableName);
    update.name = availableName;
    update.nameLower = availableName.toLowerCase();
    if (!(user.emails && user.emails.anyNotes === false))
      db.changedEmails.insert({email:user.email, user:user._id, name:user.name});
    print(_.str.sprintf('\n\n\tConflict! Username "%s" conflicts with "%s" (both sluggify to "%s"). Changing to "%s"\n\n\n',
      conflictingName, originalName, conflictingSlug, availableName));
  }
  update.slug = slug;
  slugs[slug] = user.name;
  if(user.slug === slug) return;
  print(_.str.sprintf('Setting user %s (%s) to slug %s with update %s', user.name, user.dateCreated, slug, JSON.stringify({$set:update})));
  var res = db.users.update({_id:user._id}, {$set:update});
  if(res.hasWriteError()) {
    print("\n\n\n\n\n\n\n\n\n\nOH NOOOOOOOOO\n\n\n\n\n\n\n");
    db.changedEmails.insert({email:user.email, user:user._id, name:user.name, error:true});
  }
});