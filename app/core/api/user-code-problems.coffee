fetchJson = require './fetch-json'

module.exports = {
  # levelID required
  # startDay optional
  # endDay optional
  getCommon: ({ levelSlug, startDay, endDay }, options={}) ->
    fetchJson('/db/user.code.problem/-/common_problems', _.assign {}, options, {
      method: 'POST'
      json: { slug: levelSlug, startDay, endDay }
    })
}
