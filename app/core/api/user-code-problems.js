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
  // levelID required
  // startDay optional
  // endDay optional
  getCommon ({ levelSlug, startDay, endDay }, options) {
    if (options == null) { options = {} }
    return fetchJson('/db/user.code.problem/-/common_problems', _.assign({}, options, {
      method: 'POST',
      json: { slug: levelSlug, startDay, endDay }
    }))
  }
}
