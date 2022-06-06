const fetchJson = require('./fetch-json')

const getPodcasts = () => fetchJson('/db/podcast')

module.exports = {
  getPodcasts
}
