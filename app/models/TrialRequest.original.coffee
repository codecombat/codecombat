CocoModel = require './CocoModel'
schema = require 'schemas/models/trial_request.schema'

module.exports = class TrialRequest extends CocoModel
  @className: 'TrialRequest'
  @schema: schema
  urlRoot: '/db/trial.request'

  nameString: ->
    props = @get('properties')
    values = _.filter(_.at(props, 'name', 'email'))
    return values.join(' / ')
  
  locationString: ->
    props = @get('properties')
    values = _.filter(_.at(props, 'city', 'state', 'country'))
    return values.join(' ')
    
  educationLevelString: ->
    levels = @get('properties').educationLevel or []
    return levels.join(', ')
