const fetchJson = require('./fetch-json')

module.exports = {
  get ({ courseID }, options) {
    if (options == null) { options = {} }
    return fetchJson(`/db/ai_scenario/${courseID}`, options)
  },

  getAll (options, other) {
    if (options == null) { options = {} }
    let url = '/db/ai_scenario'
    if (other) {
      url = '/' + other + url
    }
    return fetchJson(url, options)
  },

  getReleased (options) {
    if (options == null) { options = {} }
    if (options.data == null) { options.data = {} }
    if (me.isInternal()) {
      options.data.fetchInternal = true // will fetch 'released', 'beta', and 'internalRelease' courses
    } else {
      options.data.releasePhase = 'released'
      if (me.isBetaTester() || me.isStudent() || me.isAdmin()) {
        // Teacher beta testers, or any students (since students might be in teacher beta tester's classrooms) will get beta courses
        options.data.fetchBeta = true // will fetch 'released' and 'beta' courses
      }
    }
    options.data.cacheEdge = true
    return fetchJson('/db/ai_scenario', options)
  }
}
