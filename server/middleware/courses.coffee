errors = require '../commons/errors'
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
  fetchNextLevel: wrap (req, res) ->
    levelOriginal = req.params.levelOriginal
    if not database.isID(levelOriginal)
      throw new errors.UnprocessableEntity('Invalid level original ObjectId')
    
    course = yield database.getDocFromHandle(req, Course)
    if not course
      throw new errors.NotFound('Course Instance not found.')
      
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
