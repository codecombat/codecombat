const fetchJson = require('./fetch-json')

module.exports = {
  get ({ courseID }, options) {
    const effectiveOptions = options || {}
    return fetchJson(`/db/ai_scenario/${courseID}`, effectiveOptions)
  },

  getAll (options, other) {
    if (options == null) { options = {} }
    let url = '/db/ai_scenario'
    if (other) {
      url = `/${other}${url}`
    }
    return fetchJson(url, options)
  },

  async getReleased (options) {
    if (options == null) { options = {} }
    if (options.data == null) { options.data = {} }
    const results = await fetchJson('/db/ai_scenario', options)

    const phases = ['released']
    if (me.isInternal()) {
      phases.push('beta')
    }

    const filteredScenarios = results.filter(scenario => phases.includes(scenario.releasePhase))
    return filteredScenarios
  }
}
