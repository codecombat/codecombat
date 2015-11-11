mongoose = require 'mongoose'
log = require 'winston'
config = require '../../server_config'
plugins = require '../plugins/plugins'
User = require '../users/User'
jsonSchema = require '../../app/schemas/models/classroom.schema'

ClassroomSchema = new mongoose.Schema {}, {strict: false, minimize: false, read:config.mongo.readpref}

ClassroomSchema.statics.privateProperties = []
ClassroomSchema.statics.editableProperties = [
  'description'
  'name'
]

ClassroomSchema.statics.generateNewCode = (done) ->
  tryCode = ->
    code = _.sample("abcdefghijklmnopqrstuvwxyz0123456789", 8).join('')
    Classroom.findOne code: code, (err, classroom) ->
      return done() if err
      return done(code) unless classroom
      tryCode()
  tryCode()

#ClassroomSchema.plugin plugins.NamedPlugin

ClassroomSchema.pre('save', (next) ->
  return next() if @get('code')
  Classroom.generateNewCode (code) =>
    @set 'code', code
    next()
)

ClassroomSchema.methods.isOwner = (userID) ->
  return userID.equals(@get('ownerID'))
  
ClassroomSchema.methods.isMember = (userID) ->
  return _.any @get('members') or [], (memberID) -> userID.equals(memberID)

ClassroomSchema.statics.jsonSchema = jsonSchema

module.exports = Classroom = mongoose.model 'classroom', ClassroomSchema, 'classrooms'
