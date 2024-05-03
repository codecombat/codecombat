const fetchJson = require('./fetch-json')

const getPodcasts = () => fetchJson('/db/podcast', { data: { cacheEdge: true } })

const getPodcast = (podcastId) => fetchJson(`/db/podcast/${podcastId}`)

const podcastContact = (options) => {
  return fetchJson('/db/podcast/contact', {
    method: 'POST',
    json: options
  })
}

module.exports = {
  getPodcasts,
  getPodcast,
  podcastContact
}
