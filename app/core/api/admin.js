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
  clearFeatureMode (options) {
    return fetchJson('/admin/feature-mode', _.assign({}, options, { method: 'DELETE' }))
  },

  setFeatureMode (featureMode, options) {
    return fetchJson(`/admin/feature-mode/${featureMode}`, _.assign({}, options, { method: 'PUT' }))
  },

  searchUser (query) {
    let permissions, q
    let role
    if (typeof query === 'object') {
      ({
        q
      } = query);
      ({
        role
      } = query);
      ({
        permissions
      } = query)
    } else {
      q = query.replace(/role:([^ ]+) /, function (dummy, m1) {
        role = m1
        return ''
      })
    }

    const data = { adminSearch: q }
    if (role != null) { data.role = role }
    if (permissions != null) { data.permissions = permissions }
    return fetchJson('/db/user', { data })
  },

  fetchOnlineTeacherInfo (userId) {
    return fetchJson(`/db/online-teachers/${userId}`)
  },

  putOnlineTeacherInfo (_id, data) {
    return fetchJson(`/db/online-teachers/${_id}`, { method: 'PUT', json: data })
  }
}
