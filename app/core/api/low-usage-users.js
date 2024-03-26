const fetchJson = require('./fetch-json')

module.exports = {
  fetchAll () {
    return fetchJson('/db/low-usage-users?withPrepaids=true')
  }
}
