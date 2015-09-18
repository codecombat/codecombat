// Finds all email addresses of users, normalizes, and produces SHA1 hashes.
// Run while piping output to user_emails.txt.
// Then run python email-sha1s.py to get user_sha1s.txt.

var normalizedEmails = [];
var usersWithEmails = db.users.find({emailLower: {$exists: true}}, {emailLower: 1}).forEach(function(u) {
  if(u.emailLower && u.emailLower.trim().length)
    normalizedEmails.push(u.emailLower.trim().toLowerCase().replace('googlemail', 'gmail').replace(/\.(?=.*@)/g, '').replace(/\+.*@/g, '@'));
});
normalizedEmails.forEach(function(e) { print(e); });
