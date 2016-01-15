CocoModel = require './CocoModel'
schema = require 'schemas/models/trial_request.schema'

module.exports = class TrialRequest extends CocoModel
  @className: 'TrialRequest'
  @schema: schema
  urlRoot: '/db/trial.request'
