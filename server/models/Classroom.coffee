mongoose = require 'mongoose'
log = require 'winston'
config = require '../../server_config'
plugins = require '../plugins/plugins'
User = require './User'
jsonSchema = require '../../app/schemas/models/classroom.schema.coffee'
utils = require '../lib/utils'
co = require 'co'

ClassroomSchema = new mongoose.Schema {}, {strict: false, minimize: false, read:config.mongo.readpref}

ClassroomSchema.index({ownerID: 1}, {name: 'ownerID index'})
ClassroomSchema.index({members: 1}, {name: 'members index'})
ClassroomSchema.index({code: 1}, {name: 'code index', unique: true})

ClassroomSchema.statics.privateProperties = []
ClassroomSchema.statics.editableProperties = [
  'description'
  'name'
  'aceConfig'
  'averageStudentExp'
  'ageRangeMin'
  'ageRangeMax'
  'archived'
]

ClassroomSchema.statics.generateNewCode = (done) ->
  tryCode = ->
    # Use 4 code words once we get past 10M classrooms
    codeCamel = utils.getCodeCamel(3)
    code = codeCamel.toLowerCase()
    Classroom.findOne code: code, (err, classroom) ->
      return done() if err
      return done(code, codeCamel) unless classroom
      tryCode()
  tryCode()

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

ClassroomSchema.set('toObject', {
  transform: (doc, ret, options) ->
    # TODO: Remove this once classrooms are populated. This is only for when we are testing locked course content.
    if not ret.courses
      ret.courses = coursesData
    return ret unless options.req
    user = options.req.user
    unless user and (user.isAdmin() or user._id.equals(doc.get('ownerID')))
      delete ret.code
      delete ret.codeCamel
    return ret
})

module.exports = Classroom = mongoose.model 'classroom', ClassroomSchema, 'classrooms'

coursesData = []

co ->
  console.log 'Populating courses data...'
  Course = require './Course'
  Campaign = require './Campaign'
  courses = yield Course.find()
  campaigns = yield Campaign.find({_id: {$in: (course.get('campaignID') for course in courses)}})
  campaignMap = {}
  campaignMap[campaign.id] = campaign for campaign in campaigns
  coursesData = []
  for course in courses
    courseData = { _id: course._id, levels: [] }
    campaign = campaignMap[course.get('campaignID').toString()]
    levels = _.values(campaign.get('levels'))
    levels = _.sortBy(levels, 'campaignIndex')
    for level in levels
      levelData = { original: mongoose.Types.ObjectId(level.original) }
      _.extend(levelData, _.pick(level, 'type', 'slug', 'name'))
      courseData.levels.push(levelData)
    coursesData.push(courseData)
  console.log 'Populated courses data.'