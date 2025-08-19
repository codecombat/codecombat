const fetchJson = require('./fetch-json')

const getLmsClassrooms = (provider) => fetchJson(`/db/oauth2/${provider}/classes`)

const oauth2Callback = (provider, queryParams) => {
  const url = new URL(`/auth/oauth2/callback/${provider}`, window.location.origin)
  if (queryParams) {
    Object.entries(queryParams).forEach(([key, value]) => {
      url.searchParams.append(key, value)
    })
  }
  return fetchJson(url.toString(), {
    method: 'GET',
  })
}

module.exports = {
  getLmsClassrooms,
  oauth2Callback,
}
