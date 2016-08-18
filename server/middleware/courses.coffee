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
Patch = require '../models/Patch'
tv4 = require('tv4').tv4
slack = require '../slack'
{ isJustFillingTranslations } = require '../commons/deltas'
{ updateI18NCoverage } = require '../commons/i18n'

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
    select = {documentation: 1, intro: 1, name: 1, original: 1, slug: 1, thangs: 1, i18n: 1}
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
    foundLevelOriginal = false
    for level, index in levels
      if level.original.toString() is levelOriginal
        foundLevelOriginal = true
        nextLevelOriginal = levels[index+1]?.original
        break

    if not foundLevelOriginal
      throw new errors.NotFound('Level original ObjectId not found in that course')

    if not nextLevelOriginal
      return res.status(200).send({})

    dbq = Level.findOne({original: mongoose.Types.ObjectId(nextLevelOriginal)})

    dbq.sort({ 'version.major': -1, 'version.minor': -1 })
    dbq.select(parse.getProjectFromReq(req))
    level = yield dbq
    level = level.toObject({req: req})
    res.status(200).send(level)

  get: (Model, options={}) -> wrap (req, res) ->
    query = {}
    if req.query.releasePhase
      query.releasePhase = req.query.releasePhase
    dbq = Model.find(query)
    dbq.select(parse.getProjectFromReq(req))
    results = yield database.viewSearch(dbq, req)
    results = Course.sortCourses results
    res.send(results)

  postPatch: wrap (req, res) ->
    # TODO: Generalize this and use for other models, once this has been put through its paces
    course = yield database.getDocFromHandle(req, Course)
    if not course
      throw new errors.NotFound('Course not found.')
      
    originalDelta = req.body.delta
    originalCourse = course.toObject()
    changedCourse = _.cloneDeep(course.toObject(), (value) -> 
      return value if value instanceof mongoose.Types.ObjectId
      return value if value instanceof Date
      return undefined
    )
    jsondiffpatch.patch(changedCourse, originalDelta)
    
    # normalize the delta because in tests, changes to patches would sneak in and cause false positives
    # TODO: Figure out a better system. Perhaps submit a series of paths? I18N Edit Views already use them for their rows.
    normalizedDelta = jsondiffpatch.diff(originalCourse, changedCourse)
    normalizedDelta = _.pick(normalizedDelta, _.keys(originalDelta))
    reasonNotAutoAccepted = undefined

    validation = tv4.validateMultiple(changedCourse, Course.jsonSchema)
    if not validation.valid
      reasonNotAutoAccepted = 'Did not pass json schema.'
    else if not isJustFillingTranslations(normalizedDelta)
      reasonNotAutoAccepted = 'Adding to existing translations.'
    else
      course.set(changedCourse)
      updateI18NCoverage(course)
      yield course.save()
      
    patch = new Patch(req.body)
    patch.set({
      target: {
        collection: 'course'
        id: course._id
        original: course._id
      }
      creator: req.user._id
      status: if reasonNotAutoAccepted then 'pending' else 'accepted'
      created: new Date().toISOString()
      reasonNotAutoAccepted: reasonNotAutoAccepted
    })
    database.validateDoc(patch)

    if reasonNotAutoAccepted
      yield course.update({ $addToSet: { patches: patch._id }})
      patches = course.get('patches') or []
      patches.push patch._id
      course.set({patches})
    yield patch.save()

    res.status(201).send(patch.toObject({req: req}))

    docLink = "https://codecombat.com/editor/course/#{course.id}"
    message = "#{req.user.get('name')} submitted a patch to #{course.get('name')}: #{patch.get('commitMessage')} #{docLink}"
    slack.sendSlackMessage message, ['artisans']
