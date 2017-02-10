wrap = require 'co-express'
errors = require '../commons/errors'
database = require '../commons/database'
config = require '../../server_config'

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
  
calculateLinesOfCode = (req, res) ->
  { courseIDs, classroomIDs } = req.query
  console.log {courseIDs, classroomIDs}
  # Get total number of lines of code for all sessions that are in
  # one of these classrooms AND one of these courses
  res.send({ linesOfCode: "42" })

module.exports = {
  putFeatureMode
  deleteFeatureMode
  calculateLinesOfCode
}
