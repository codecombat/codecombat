wrap = require 'co-express'
errors = require '../commons/errors'
database = require '../commons/database'
config = require '../../server_config'
LevelSession = require '../models/LevelSession'
Classroom = require '../models/Classroom'


putFeatureMode = (req, res) ->
  if not req.user
    throw new errors.Unauthorized('You must be logged in')
    
  unless req.session.amActually or req.user.isAdmin()
    throw new errors.Forbidden('You cannot switch your feature mode')
    
  req.session.featureMode = req.params.featureMode
  res.send({})

deleteFeatureMode = (req, res) ->
  delete req.session.featureMode
  res.send({})
  
calculateLinesOfCode = wrap (req, res) ->
  { courseIDs, classroomIDs } = req.query
  #classroomIDs = ['5840da462381831f00d455d3']

  classrooms = yield Classroom.find({_id: {$in: classroomIDs}}).exec()
  students = classrooms.reduce (a,b) ->
    a.concat b.get('members').map (x) -> x.toString()
  , []

  levels = classrooms.reduce (a,b) ->
    a.concat.apply a, b.get('courses').filter((x) -> courseIDs.indexOf(x._id.toString()) != -1).map (x) -> x.levels
  , [] 

  levels = _.uniq levels.map (x) -> x.slug #TODO: Use Origionals

  #console.log(JSON.stringify(classrooms, null, '  '))
  #console.log "L", levels
  #console.log {courseIDs, classroomIDs, classrooms}
  # Get total number of lines of code for all sessions that are in
  # one of these classrooms AND one of these courses
  query = 
    creator: {$in: students}
    "levelID": {$in: levels}
    #"state.complete": true
  console.log query
  result = yield LevelSession.mapReduce
    query: query
    map: () ->
      emit('programs', 1)
      emit('students', @creatorName)
      #emit('programs_' + @creatorName, 1)

      if @code and @code['hero-placeholder'] and @code['hero-placeholder'].plan?
        emit('linesOfCode', @code['hero-placeholder'].plan.split(/\n+/).length)

      emit('playtime', @playtime) if @playtime?
      emit('lang:' + (@codeLanguage or @primerLangauge), 1)
      #emit('levelsIDs:' + @levelID, 1)
    reduce: (k, vals) -> 
      if k is 'students'
        t = vals.join ","
        Array.from(new Set(t.split ',')).join ','
      else
        vals.reduce ((a,b) -> a+b), 0

  vals = {courseIDs, classroomIDs}
  (vals[v._id] = v.value for v in result)
  if vals.students
    vals.studentCount = vals.students.split(/,/).length
  res.send vals

module.exports = {
  putFeatureMode
  deleteFeatureMode
  calculateLinesOfCode
}
