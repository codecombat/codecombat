// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let TrialRequest
const CocoModel = require('./CocoModel')
const schema = require('schemas/models/trial_request.schema')

module.exports = (TrialRequest = (function () {
  TrialRequest = class TrialRequest extends CocoModel {
    static initClass () {
      this.className = 'TrialRequest'
      this.schema = schema
      this.prototype.urlRoot = '/db/trial.request'
    }

    nameString () {
      const props = this.get('properties')
      const values = _.filter(_.at(props, 'name', 'email'))
      return values.join(' / ')
    }

    locationString () {
      const props = this.get('properties')
      const values = _.filter(_.at(props, 'city', 'state', 'country'))
      return values.join(' ')
    }

    educationLevelString () {
      const levels = this.get('properties').educationLevel || []
      return levels.join(', ')
    }
  }
  TrialRequest.initClass()
  return TrialRequest
})())
