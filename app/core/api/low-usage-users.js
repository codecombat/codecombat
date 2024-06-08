const fetchJson = require('./fetch-json')

module.exports = {
  fetchAll () {
    return fetchJson('/db/low-usage-users?withPrepaids=true')
  },
  addAction ({ lowUsageUserId, action }, options = {}) {
    return fetchJson(`/db/low-usage-users/${lowUsageUserId}/action`, _.assign({}, options, {
      method: 'POST',
      json: { action }
    }))
  }
}
