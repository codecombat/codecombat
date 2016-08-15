# Usage: 
# > coffee -c scripts/node/fixEmailFormattedUsernames.coffee; node scripts/node/fixEmailFormattedUsernames.js run

require('coffee-script');
require('coffee-script/register');

_ = require 'lodash'
sendwithus = require '../../server/sendwithus'
log = require 'winston'
str = require 'underscore.string'
co = require 'co'

filter = /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,63}$/i

changedUsernameTemplate = _.template("
<p>
  Hi, CodeCombat user!
</p>

<p>
  Just letting you know we've made a change to your account settings which may change how you log in. Here are your old settings:
</p>

<ul>
  <li>Old username: <%= oldUsername %></li>
  <li>Old email: <%= oldEmail %></li>
</ul>

</p>
  Your old username was an email address, but to reduce confusion, we now make sure email addresses can't be used as usernames.
  <b><%= specialMessage %></b>
  Here are your new settings:
</p>

<ul>
  <li>New username: <%= newUsername %></li>
  <li>New email: <%= newEmail %></li>
</ul>

<p>
  Please <a href='https://codecombat.com/account/settings'>visit the site</a> if you would like to update your settings.
  And let us know if you have any questions!
</p>
")

exports.run = ->
  co ->
    mongoose = require 'mongoose'
    User = require '../../server/models/User'
    users = yield User.find({nameLower: {$regex: filter}}).select({name:1, email:1, anonymous:1, slug:1})
    console.log 'found', users.length, 'users'
  
    for user in users
      oldUsername = user.get('name')
      oldEmail = user.get('email')
      newUsername = null
      newEmail = null
      specialMessage = ''
  
      if not oldEmail
        otherUser = yield User.findByEmail(oldUsername)
        if otherUser
          specialMessage = "Since you had no email set, we would have made your old username your new email. 
                            But '#{oldUsername}' is already used by another account as an email by another account,
                            so instead we changed your username."
          newUsername = str.slugify(oldUsername)
          newEmail = ''
  
        else
          specialMessage = "Since you had no email set, we simply made your old username your new email instead."
          newEmail = oldUsername
          newUsername = ''
  
  
      else if oldEmail is oldUsername
        specialMessage = "Since your email and username are the same, we simply removed your username."
        newUsername = ''
        newEmail = oldEmail
  
  
      else if not filter.test(oldEmail)
        otherEmailUser = yield User.findByEmail(oldUsername)
        otherUsernameUser = yield User.findByName(oldEmail)
        if otherEmailUser
          specialMessage = "Since your old email looks like a username and your old username looks like an email, 
                            we would have swapped them on your account.
                            But '#{oldUsername}' is already used as an email by another account,
                            so instead we changed your username."
          newUsername = str.slugify(oldUsername)
          newEmail = oldEmail
  
        else if otherUsernameUser
          specialMessage = "Since your old email looks like a username and your old username looks like an email, 
                            we would have swapped them on your account.
                            But '#{oldEmail}' is already used as a username by another account,
                            so instead we changed your username."
          newUsername = str.slugify(oldUsername)
          newEmail = oldEmail
        else
          specialMessage = "Since your old email looks like a username and your old username looks like an email,
                            we swapped them on your account."
          newUsername = oldEmail
          newEmail = oldUsername
  
  
      else if oldUsername and oldEmail
        # Since oldEmail passed the email filter, 
        specialMessage = "Since your old email is valid, we simply removed your username."
        newUsername = ''
        newEmail = oldEmail
  
  
      else
        console.log('unhandled user', user.toObject())
        throw new Error('Unhandled user')
  
      user.set({name: newUsername, email: newEmail})
      console.log JSON.stringify({
        oldUsername, oldEmail, newUsername, newEmail, specialMessage, _id: user.id
      })
      yield user.save()
  
      content = changedUsernameTemplate({
        oldUsername: oldUsername or '<i>(no username)</i>'
        oldEmail: oldEmail or '<i>(no email)</i>'
        newUsername: newUsername or '<i>(no username)</i>'
        newEmail: newEmail or '<i>(no email)</i>'
        specialMessage
      })
  
      context =
        template: sendwithus.templates.plain_text_email
        recipient:
          address: oldUsername
        sender:
          address: 'team@codecombat.com'
          name: 'CodeCombat Team'
        template_data:
          subject: 'Your Username Has Changed'
          contentHTML: content
  
      # Also send to the original email if it's valid
      if filter.test(oldEmail)
        context.cc = [
          { address: oldEmail }
        ]
  
      yield sendwithus.api.sendAsync(context)
  
    return 'Done'

if _.last(process.argv) is 'run'
  database = require '../../server/commons/database'
  mongoose = require 'mongoose'
  
  ### SET UP ###
  do (setupLodash = this) ->
    GLOBAL._ = require 'lodash'
    _.str = require 'underscore.string'
    _.mixin _.str.exports()
    GLOBAL.tv4 = require('tv4').tv4
  
  database.connect()
  co ->
    yield exports.run()
    process.exit()
  
