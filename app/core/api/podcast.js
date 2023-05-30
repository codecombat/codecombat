import fetchJson from './fetch-json';

const getPodcasts = () => fetchJson('/db/podcast')

const getPodcast = (podcastId) => fetchJson(`/db/podcast/${podcastId}`)

const podcastContact = (options) => {
  return fetchJson('/db/podcast/contact', {
    method: 'POST',
    json: options
  })
}

export default {
  getPodcasts,
  getPodcast,
  podcastContact
};
