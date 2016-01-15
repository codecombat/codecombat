mongoose = require 'mongoose'
log = require 'winston'
config = require '../../server_config'
plugins = require '../plugins/plugins'
User = require '../users/User'
jsonSchema = require '../../app/schemas/models/classroom.schema'

ClassroomSchema = new mongoose.Schema {}, {strict: false, minimize: false, read:config.mongo.readpref}

ClassroomSchema.index({ownerID: 1}, {name: 'ownerID index'})
ClassroomSchema.index({members: 1}, {name: 'members index'})
ClassroomSchema.index({code: 1}, {name: 'code index', unique: true})

ClassroomSchema.statics.privateProperties = []
ClassroomSchema.statics.editableProperties = [
  'description'
  'name'
  'aceConfig'
]

# 250 words; will want to use 4 code words once we get past 10M classrooms.
words = 'angry apple arm army art baby back bad bag ball bath bean bear bed bell best big bird bite blue boat book box boy bread burn bus cake car cat chair city class clock cloud coat coin cold cook cool corn crash cup dark day deep desk dish dog door down draw dream drink drop dry duck dust east eat egg enemy eye face false farm fast fear fight find fire flag floor fly food foot fork fox free fruit full fun funny game gate gift glass goat gold good green hair half hand happy heart heavy help hide hill home horse house ice idea iron jelly job jump key king lamp large last late lazy leaf left leg life light lion lock long luck map mean milk mix moon more most mouth music name neck net new next nice night north nose old only open page paint pan paper park party path pig pin pink place plane plant plate play point pool power pull push queen rain ready red rest rice ride right ring road rock room run sad safe salt same sand sell shake shape share sharp sheep shelf ship shirt shoe shop short show sick side silly sing sink sit size sky sleep slow small snow sock soft soup south space speed spell spoon star start step stone stop sweet swim sword table team thick thin thing think today tooth top town tree true turn type under want warm watch water west wide win word yes zoo'.split(' ')

ClassroomSchema.statics.generateNewCode = (done) ->
  tryCode = ->
    codeCamel = _.map(_.sample(words, 3), (s) -> s[0].toUpperCase() + s.slice(1)).join('')
    code = codeCamel.toLowerCase()
    Classroom.findOne code: code, (err, classroom) ->
      return done() if err
      return done(code, codeCamel) unless classroom
      tryCode()
  tryCode()

#ClassroomSchema.plugin plugins.NamedPlugin

ClassroomSchema.pre('save', (next) ->
  return next() if @get('code')
  Classroom.generateNewCode (code, codeCamel) =>
    @set 'code', code
    @set 'codeCamel', codeCamel
    next()
)

ClassroomSchema.methods.isOwner = (userID) ->
  return userID.equals(@get('ownerID'))

ClassroomSchema.methods.isMember = (userID) ->
  return _.any @get('members') or [], (memberID) -> userID.equals(memberID)

ClassroomSchema.statics.jsonSchema = jsonSchema

module.exports = Classroom = mongoose.model 'classroom', ClassroomSchema, 'classrooms'
