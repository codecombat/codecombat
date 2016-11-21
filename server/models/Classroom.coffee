mongoose = require 'mongoose'
log = require 'winston'
config = require '../../server_config'
plugins = require '../plugins/plugins'
jsonSchema = require '../../app/schemas/models/classroom.schema.coffee'
utils = require '../lib/utils'
co = require 'co'
Campaign = require './Campaign'
Course = require './Course'

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
ClassroomSchema.statics.postEditableProperties = []

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

ClassroomSchema.methods.generateCoursesData = co.wrap (isAdmin=false) ->
  # Helper function for generating the latest version of courses
  query = {}
  query = {releasePhase: 'released'} unless isAdmin
  courses = yield Course.find(query)
  courses = Course.sortCourses courses
  campaigns = yield Campaign.find({_id: {$in: (course.get('campaignID') for course in courses)}})
  campaignMap = {}
  campaignMap[campaign.id] = campaign for campaign in campaigns
  classLanguage = @get('aceConfig')?.language
  coursesData = []
  for course in courses
    courseData = { _id: course._id, levels: [] }
    campaign = campaignMap[course.get('campaignID').toString()]
    levels = _.values(campaign.get('levels'))
    levels = _.sortBy(levels, 'campaignIndex')
    for level in levels
      continue if classLanguage and level.primerLanguage is classLanguage
      levelData = { original: mongoose.Types.ObjectId(level.original) }
      _.extend(levelData, _.pick(level, 'type', 'slug', 'name', 'practice', 'practiceThresholdMinutes', 'primerLanguage', 'shareable'))
      courseData.levels.push(levelData)
    coursesData.push(courseData)
  coursesData

ClassroomSchema.methods.generateCourseData = co.wrap (courseId) ->
  # Helper function for generating the latest version of a course
  course = yield Course.findById(courseId)
  campaign = yield Campaign.findById({_id: course.get('campaignID')})
  classLanguage = @get('aceConfig')?.language
  courseData = { _id: course._id, levels: [] }
  levels = _.values(campaign.get('levels'))
  levels = _.sortBy(levels, 'campaignIndex')
  for level in levels
    continue if classLanguage and level.primerLanguage is classLanguage
    levelData = { original: mongoose.Types.ObjectId(level.original) }
    _.extend(levelData, _.pick(level, 'type', 'slug', 'name', 'practice', 'practiceThresholdMinutes', 'primerLanguage', 'shareable'))
    courseData.levels.push(levelData)
  courseData

ClassroomSchema.methods.setUpdatedCourse = co.wrap (courseId) ->
  # Update existing or add missing course
  latestCourse = yield @generateCourseData(courseId)
  updatedCourses = _.clone(@get('courses') or [])
  existingIndex = _.findIndex(updatedCourses, (c) -> c._id.equals(courseId))
  if existingIndex >= 0
    updatedCourses.splice(existingIndex, 1, latestCourse)
  else
    # TODO: does this need to be inserted in order?
    updatedCourses.push(latestCourse)
  @set('courses', updatedCourses)

ClassroomSchema.methods.setUpdatedCourses = co.wrap (isAdmin=false, addNewCoursesOnly=true) ->
  # Add missing courses, and update existing courses if addNewCoursesOnly=false
  coursesData = yield @generateCoursesData(isAdmin)
  if addNewCoursesOnly
    newestCoursesData = coursesData
    coursesData = @get('courses') or []
    existingCourseIds = _(coursesData).pluck('_id').map((id) -> id + '').value()
    existingCourseMap = _.zipObject(existingCourseIds, coursesData)
    coursesData = _.map(newestCoursesData, (newCourseData) -> existingCourseMap[newCourseData._id+''] or newCourseData)
  @set('courses', coursesData)

ClassroomSchema.statics.jsonSchema = jsonSchema

ClassroomSchema.set('toObject', {
  transform: (doc, ret, options) ->
    return ret unless options.req
    user = options.req.user
    unless user and (user.isAdmin() or user._id.equals(doc.get('ownerID')))
      delete ret.code
      delete ret.codeCamel
    return ret
})

module.exports = Classroom = mongoose.model 'classroom', ClassroomSchema, 'classrooms'
