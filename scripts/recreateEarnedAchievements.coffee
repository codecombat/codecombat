database = require '../server/commons/database'
mongoose = require 'mongoose'
log = require 'winston'
async = require 'async'

### SET UP ###
do (setupLodash = this) ->
  GLOBAL._ = require 'lodash'
  _.str = require 'underscore.string'
  _.mixin _.str.exports()
  GLOBAL.tv4 = require('tv4').tv4

database.connect()

LocalMongo = require '../app/lib/LocalMongo'
User = require '../server/models/User'
EarnedAchievement = require '../server/models/EarnedAchievement'
Achievement = require '../server/models/Achievement'
Achievement.loadAchievements (achievementCategories) ->
  # Really, it's just the 'users' category, since we don't keep all the LevelSession achievements in memory, rather letting the clients make those.
  userAchievements = achievementCategories.users
  console.log 'There are', userAchievements.length, 'user achievements.'

  t0 = new Date().getTime()
  total = 100000
  #testUsers = ['livelily+test31@gmail.com', 'livelily+test37@gmail.com']
  if testUsers?
    userQuery = emailLower: {$in: testUsers}
  else
    userQuery = anonymous: false
  User.count userQuery, (err, count) -> total = count

  onFinished = ->
    t1 = new Date().getTime()
    runningTime = ((t1-t0)/1000/60/60).toFixed(2)
    console.log "we finished in #{runningTime} hours"
    process.exit()

  # Fetch every single user. This tends to get big so do it in a streaming fashion.
  userStream = User.find(userQuery).sort('_id').stream()
  streamFinished = false
  usersTotal = 0
  usersFinished = 0
  totalAchievementsExisting = 0
  totalAchievementsCreated = 0
  numberRunning = 0
  doneWithUser = ->
    ++usersFinished
    numberRunning -= 1
    userStream.resume()
    onFinished?() if streamFinished and usersFinished is usersTotal

  userStream.on 'error', (err) -> log.error err
  userStream.on 'close', -> streamFinished = true
  userStream.on 'data', (user) ->
    ++usersTotal
    numberRunning += 1
    userStream.pause() if numberRunning > 20
    userID = user.get('_id').toHexString()
    userObject = user.toObject()

    # Fetch all of a user's earned achievements
    EarnedAchievement.find {user: userID}, (err, alreadyEarnedAchievements) ->
      log.error err if err

      achievementsExisting = 0
      achievementsCreated = 0
      for achievement in userAchievements
        #console.log "Testing", achievement.get('name'), achievement.get('_id') if testUsers?
        shouldBeAchieved = LocalMongo.matchesQuery userObject, achievement.get('query')
        continue unless shouldBeAchieved  # Could delete existing ones that shouldn't be achieved if we wanted.
        earnedAchievement = _.find(alreadyEarnedAchievements, (ea) -> ea.get('user') is userID and ea.get('achievement') is achievement.get('_id').toHexString())
        if earnedAchievement
          #console.log "... already earned #{achievement.get('name')} #{achievement.get('_id')} for user: #{user.get('name')} #{user.get('_id')}" if testUsers?
          ++achievementsExisting
          continue
        #console.log "Making an achievement: #{achievement.get('name')} #{achievement.get('_id')} for user: #{user.get('name')} #{user.get('_id')}" if testUsers?
        ++achievementsCreated
        EarnedAchievement.createForAchievement achievement, user
      
      totalAchievementsExisting += achievementsExisting
      totalAchievementsCreated += achievementsCreated
      pctDone = (100 * usersFinished / total).toFixed(2)
      console.log "Created #{achievementsCreated}, existing #{achievementsExisting} EarnedAchievements for #{user.get('name') or '???'} (#{user.get('_id')}) (#{pctDone}%, totals #{totalAchievementsExisting} existing, #{totalAchievementsCreated} created)"
      doneWithUser()
