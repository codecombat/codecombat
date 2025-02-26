const fetchJson = require('./fetch-json')

const getLmsClassrooms = (provider) => fetchJson(`/db/oauth2/${provider}/classes`)

module.exports = {
  getLmsClassrooms,
}
