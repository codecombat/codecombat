// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let TrialRequestCollection
const CocoCollection = require('collections/CocoCollection')
const TrialRequest = require('models/TrialRequest')

module.exports = (TrialRequestCollection = (function () {
  TrialRequestCollection = class TrialRequestCollection extends CocoCollection {
    static initClass () {
      this.prototype.url = '/db/trial.request'
      this.prototype.model = TrialRequest
    }

    fetchOwn (options) {
      options = _.extend({ data: {} }, options)
      options.data.applicant = me.id
      return this.fetch(options)
    }

    fetchByApplicant (applicant) {
      return this.fetch({
        data: { applicant }
      })
    }
  }
  TrialRequestCollection.initClass()
  return TrialRequestCollection
})())
