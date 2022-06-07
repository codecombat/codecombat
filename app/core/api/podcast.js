const fetchJson = require('./fetch-json')

const getPodcasts = () => fetchJson('/db/podcast')

const podcastContact = (options) => {
  return fetchJson('/db/podcast/contact', {
    method: 'POST',
    json: options
  })
}

module.exports = {
  getPodcasts,
  podcastContact
}
