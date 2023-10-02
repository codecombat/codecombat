const fetchJson = require('./fetch-json')

const getCredits = (action) => fetchJson(`/db/credits/${action}`)

module.exports = {
  getCredits
}
