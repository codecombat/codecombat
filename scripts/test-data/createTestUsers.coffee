#
# Test User Creation Script
#
# Creates test users, with optional group (clan or classroom) for them
#
# Usage:
#   node_modules/coffee-script/bin/coffee scripts/node/test-data/createTestUsers.coffee -n run [numUsers] [prefix] [group group_id]
#
# Args:
#   numUsers - number of users to create, default 1
#   prefix - prefix for user/group name, default 'test'
#   group - 'clan' or 'classroom' (default: no group membership)
#   group_id - id of an existing clan or classroom to put the new users into, or id of an existing user to own a newly-created one
#
_ = require 'lodash'
log = require 'winston'
str = require 'underscore.string'
co = require 'co'

exports.run = (numUsers, prefix, group, group_id) ->
  co ->
    mongoose = require 'mongoose'
    User = require '../../server/models/User'
    Clan = require '../../server/models/Clan'
    Classroom = require '../../server/models/Classroom'

    console.log "test users to create:", numUsers
    console.log "test user name prefix:", prefix

    if group?
      group_class = if group is 'clan' then Clan else Classroom

      if group_id
        try
          console.log 'searching group'
          group_inst = yield group_class.findOne({_id: group_id})
        catch e
          console.error e
        if group_inst
          console.log 'Found group:', group.name, group.get('members')
        else
          console.log 'Creating new group'
          group_inst = group_class(
            ownerID: group_id
            name: "#{prefix} #{group}"
          )
          try
            yield group_inst.save()
            console.log "Created new #{group}: #{group_inst.name}"
          catch e
            console.error "Could not create group:", e

    if numUsers > 0
      users = []
      for i in [1..numUsers]
        user = User(
          name: prefix + i
          password: prefix + i
          email: prefix + i + '@' + prefix + '.example'
        )
        try
          yield user.save()
          console.log 'Created user:', user.name
          users.push user
          if group_inst
            yield group_inst.update({ '$push': {members: user._id}})
        catch e
          console.error e

    return 'Done'

if process.argv[0] is 'coffee'
  proc_arg = process.argv[3]
  user_args = process.argv[4..]
else
  proc_arg = process.argv[2]
  user_args = process.argv[3..]

if proc_arg is 'run'
  database = require '../../server/commons/database'
  mongoose = require 'mongoose'

  ### SET UP ###
  do (setupLodash = this) ->
    GLOBAL._ = require 'lodash'
    _.str = require 'underscore.string'
    _.mixin _.str.exports()
    GLOBAL.tv4 = require('tv4').tv4

  numUsers = if user_args[0] then user_args[0] | 0 else 1
  userPrefix = user_args[1] ? 'test'
  group = user_args[2]
  group_id = user_args[3]

  database.connect()
  co ->
    yield exports.run(numUsers, userPrefix, group, group_id)
    process.exit()
  
