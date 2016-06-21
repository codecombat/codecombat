mongoose = require 'mongoose'
plugins = require '../plugins/plugins'
jsonSchema = require '../../app/schemas/models/user-polls-record.schema.coffee'
log = require 'winston'
Poll = require './Poll'
User = require './User'

UserPollsRecordSchema = new mongoose.Schema {}, {strict: false, minimize: false}

UserPollsRecordSchema.index {user: 1}, {unique: true, name: 'user polls record index'}

UserPollsRecordSchema.post 'init', (doc) ->
  doc.previousPolls ?= _.clone doc.get('polls') ? {}

UserPollsRecordSchema.pre 'save', (next) ->
  return next() unless @previousPolls?
  @set 'changed', new Date()
  rewards = @get('rewards') ? {}
  level = @get('level') ? {}
  gemDelta = 0
  for pollID, answer of @get('polls') ? {}
    previousAnswer = @previousPolls[pollID]
    updatePollVotes @get('user'), pollID, answer, previousAnswer unless answer is previousAnswer
    unless rewards[pollID]
      rewards[pollID] = reward = random: Math.random(), level: level
      gemDelta += Math.ceil 2 * reward.random * reward.level
      @set 'rewards', rewards
      @markModified 'rewards'
  updateUserGems @get('user'), gemDelta if gemDelta
  next()

updatePollVotes = (userID, pollID, answer, previousAnswer) ->
  Poll.findById mongoose.Types.ObjectId(pollID), {}, (err, poll) ->
    return log.error err if err
    answers = poll.get 'answers'
    _.find(answers, key: answer)?.votes++
    _.find(answers, key: previousAnswer)?.votes-- if previousAnswer
    poll.set 'answers', answers
    poll.markModified 'answers'
    poll.save (err, newPoll, result) ->
      return log.error err if err
    updateUserProperty userID, userProperty, answer if userProperty = poll.get 'userProperty'

updateUserProperty = (userID, userProperty, answer) ->
  update = $set: {"#{userProperty}": answer}
  User.update {_id: mongoose.Types.ObjectId(userID)}, update, (err, result) ->
    return log.error err if err

updateUserGems = (userID, gemDelta) ->
  return unless gemDelta
  update = $inc: {'earned.gems': gemDelta}
  User.update {_id: mongoose.Types.ObjectId(userID)}, update, (err, result) ->
    return log.error err if err

UserPollsRecordSchema.statics.privateProperties = []
UserPollsRecordSchema.statics.editableProperties = ['polls']
UserPollsRecordSchema.statics.jsonSchema = jsonSchema

module.exports = UserPollsRecord = mongoose.model 'user.polls.record', UserPollsRecordSchema, 'user.polls.records'
