errors = require '../commons/errors'
log = require 'winston'
wrap = require 'co-express'
database = require '../commons/database'
mongoose = require 'mongoose'
Campaign = require '../models/Campaign'
CourseInstance = require '../models/CourseInstance'
Classroom = require '../models/Classroom'
Course = require '../models/Course'
User = require '../models/User'
Level = require '../models/Level'
parse = require '../commons/parse'

module.exports =

  fetchLevelSolutions: wrap (req, res) ->
    unless req.user?.isTeacher() or req.user?.isAdmin()
      log.debug "courses.fetchLevelSolutions: level solutions only for teachers, (#{req.user?.id})"
      throw new errors.Forbidden()

    course = yield database.getDocFromHandle(req, Course)
    throw new errors.NotFound('Course not found.') unless course

    campaign = yield Campaign.findById course.get('campaignID')
    throw new errors.NotFound('Campaign not found.') unless campaign

    # TODO: why does campaign.get('levels') return opposite order from direct db query?
    sortedLevelIDs = _.keys campaign.get('levels')
    sortedLevelIDs.reverse()

    levelOriginals = (mongoose.Types.ObjectId(levelID) for levelID in sortedLevelIDs)
    query = { original: { $in: levelOriginals }, slug: { $exists: true }}
    select = {documentation: 1, intro: 1, name: 1, original: 1, practice: 1, assessment: 1, slug: 1, thangs: 1, i18n: 1, primerLanguage: 1, shareable: 1}
    levels = yield Level.find(query).select(select).lean()
    levels.sort((a, b) -> sortedLevelIDs.indexOf(a.original + '') - sortedLevelIDs.indexOf(b.original + ''))
    res.status(200).send(levels)

  fetchNextLevel: wrap (req, res) ->
    levelOriginal = req.params.levelOriginal
    if not database.isID(levelOriginal)
      throw new errors.UnprocessableEntity('Invalid level original ObjectId')
    
    course = yield database.getDocFromHandle(req, Course)
    if not course
      throw new errors.NotFound('Course not found.')
      
    campaign = yield Campaign.findById course.get('campaignID')
    if not campaign
      throw new errors.NotFound('Campaign not found.')
    
    levels = _.values(campaign.get('levels'))
    levels = _.sortBy(levels, 'campaignIndex')
    
    nextLevelOriginal = null
    nextAssessmentOriginal = null
    foundLevelOriginal = false
    for level, index in levels
      if level.original.toString() is levelOriginal
        foundLevelOriginal = true
        continue
      if foundLevelOriginal
        if level.assessment
          nextAssessmentOriginal = level.original
        else
          nextLevelOriginal = level.original
          break

    if not foundLevelOriginal
      throw new errors.NotFound('Level original ObjectId not found in that course')

    unless nextLevelOriginal or nextAssessmentOriginal
      return res.status(200).send({level: {}, assessment: {}})

    level = {}
    if nextLevelOriginal
      dbq = Level.findOne({original: mongoose.Types.ObjectId(nextLevelOriginal)})
      dbq.sort({ 'version.major': -1, 'version.minor': -1 })
      dbq.select(parse.getProjectFromReq(req))
      level = yield dbq
      level = level.toObject({req: req})
      
    assessment = {}
    if nextAssessmentOriginal and req.user.hasPermission('assessments')
      dbq = Level.findOne({original: mongoose.Types.ObjectId(nextAssessmentOriginal)})
      dbq.sort({ 'version.major': -1, 'version.minor': -1 })
      dbq.select(parse.getProjectFromReq(req))
      assessment = yield dbq
      assessment = assessment.toObject({req: req})
      
    res.status(200).send({ level, assessment })

  get: (Model, options={}) -> wrap (req, res) ->
    query = {}
    if req.query.releasePhase
      query.releasePhase = req.query.releasePhase
    dbq = Model.find(query)
    dbq.select(parse.getProjectFromReq(req))
    results = yield database.viewSearch(dbq, req)
    results = Course.sortCourses results
    res.send(results)
