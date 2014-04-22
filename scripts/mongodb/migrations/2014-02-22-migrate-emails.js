// Did not migrate anonymous users because they get their properties setup on signup.

// migrate the most common subscription configs with mass update commands
db.users.update({anonymous:false, emailSubscriptions:['announcement', 'notification'], emails:{$exists:false}}, {$set:{emails:{}}}, {multi:true});
db.users.update({anonymous:false, emailSubscriptions:[], emails:{$exists:false}}, {$set:{emails:{anyNotes:{enabled:false}, generalNews:{enabled:false}}}}, {multi:true});

// migrate the rest one by one
emailMap =   {
  announcement: 'generalNews',
  developer: 'archmageNews',
  tester: 'adventurerNews',
  level_creator: 'artisanNews',
  article_editor: 'scribeNews',
  translator: 'diplomatNews',
  support: 'ambassadorNews',
  notification: 'anyNotes'
};

db.users.find({anonymous:false, emails:{$exists:false}}).forEach(function(u) {
  emails = {anyNotes:{enabled:false}, generalNews:{enabled:false}};
  var oldEmailSubs = u.emailSubscriptions || ['notification', 'announcement'];
  for(var email in oldEmailSubs) {
    var oldEmailName = oldEmailSubs[email];
    var newEmailName = emailMap[oldEmailName];
    if(!newEmailName) {
      print('STOP, COULD NOT FIND EMAIL NAME', oldEmailName);
      return false;
    }
    emails[newEmailName] = {enabled:true};
  }
  u.emails = emails;
  db.users.save(u);
});

// Done. No STOP error when this was run.