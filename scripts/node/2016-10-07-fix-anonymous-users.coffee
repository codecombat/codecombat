# Usage: 
# > coffee -c scripts/node/2016-10-07-fix-anonymous-users.coffee; node scripts/node/2016-10-07-fix-anonymous-users.js run

require('coffee-script');
require('coffee-script/register');

_ = require 'lodash'
sendwithus = require '../../server/sendwithus'
log = require 'winston'
str = require 'underscore.string'
co = require 'co'

changedUsernameTemplate = _.template("
<p>
  Hi, CodeCombat user!
</p>

<p>
  Just letting you know we've made a change to your account settings which may change how you log in. Here are your old settings:
</p>

<ul>
  <li>Old username: <%= oldUsername %></li>
</ul>

</p>
  Your old username conflicts with another user's. This should have been prevented on signup, our apologies!
  Here are your new settings:
</p>

<ul>
  <li>New username: <%= newUsername %></li>
</ul>

<p>
  Please <a href='https://codecombat.com/account/settings'>visit the site</a> if you would like to update your settings.
  And let us know if you have any questions!
</p>

<p>
- CodeCombat Team
</p>
")

exports.run = ->
  co ->
    mongoose = require 'mongoose'
    User = require '../../server/models/User'
    users = yield User.find({
      $and: [
        { emailLower: {$exists: true}},
        { anonymous: true },
      ],
      slug: {$exists: false}
    }).limit(1000).sort({_id:-1})
    console.log 'found', users.length, 'users'

    successes = 0
    for user in users
      try
        console.log 'save', user.id, user.get('name'), user.get('email'), user.get('anonymous'), user.get('slug'), user.get('emailLower')
        yield user.save()
        successes += 1
      catch e
        if e.response.message is 'is already in use' and e.response.property is 'name'
          oldUsername = user.get('name')
          newUsername = yield User.unconflictNameAsync(user.get('name'))
          content = changedUsernameTemplate({
            oldUsername
            newUsername
          })
          console.log "\tChange name '#{oldUsername}' => '#{newUsername}'"
          context =
            template: sendwithus.templates.plain_text_email
            recipient:
              address: user.get('email')
            sender:
              address: 'team@codecombat.com'
              name: 'CodeCombat Team'
            template_data:
              subject: 'Your Username Has Changed'
              contentHTML: content
          user.set('name': newUsername)
          yield user.save()
          yield sendwithus.api.sendAsync(context)
#          return


    console.log("Fixed #{successes} / #{users.length} users")
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
  
