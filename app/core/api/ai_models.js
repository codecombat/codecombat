const fetchJson = require('./fetch-json')

module.exports = {
  get ({ courseID: modelID }, options) {
    const effectiveOptions = options || {}
    return fetchJson(`/db/ai_model/${modelID}`, effectiveOptions)
  },

  getAll (options = {}) {
    const url = '/db/ai_model'
    return fetchJson(url, {
      ...options,
      data: {
        cacheEdge: true,
        ...(options.data || {})
      }
    })
  }
}
