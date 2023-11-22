// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const fetchJson = require('./fetch-json')

module.exports = {
  post (trialRequest, options) {
    return fetchJson('/db/trial.request', _.assign({}, options, {
      method: 'POST',
      json: trialRequest
    }))
  },

  getOwn (options) {
    if (options == null) { options = {} }
    if (options.data == null) { options.data = {} }
    options.data.applicant = me.id
    return fetchJson('/db/trial.request', options)
  },

  update (trialRequest, options) {
    if (!trialRequest._id) {
      // eslint-disable-next-line prefer-promise-reject-errors
      return Promise.reject('Trial request id missing')
    }
    return fetchJson(`/db/trial.request/update/${trialRequest._id}`, _.assign({}, options, {
      method: 'PUT',
      json: trialRequest
    }))
  }
}
