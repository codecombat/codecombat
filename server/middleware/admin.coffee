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
  

module.exports = {
  putFeatureMode
  deleteFeatureMode
}
