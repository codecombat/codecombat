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

User = require '../server/models/User'
Payment = require '../server/models/Payment'
PaymentHandler = require '../server/handlers/payment_handler'

t0 = new Date().getTime()
total = 100000
#testUsers = ['livelily+test31@gmail.com', 'livelily+test37@gmail.com']
if testUsers?
  userQuery = emailLower: {$in: testUsers}
else
  userQuery = $or: [
    {stripe: {$exists: true}}
    {'purchased.gems': {$gt: 0}}
  ]
User.count userQuery, (err, count) -> total = count

onFinished = ->
  t1 = new Date().getTime()
  runningTime = ((t1-t0)/1000/60/60).toFixed(2)
  console.log "we finished in #{runningTime} hours"
  process.exit()

userStream = User.find(userQuery).sort('_id').stream()
streamFinished = false
usersTotal = 0
usersFinished = 0
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
  user._id = user.get('_id')
  PaymentHandler.recalculateGemsFor user, doneWithUser, true
