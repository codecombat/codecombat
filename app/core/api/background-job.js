const fetchJson = require('./fetch-json')

function create (jobType, input) {
  return fetchJson('/db/background-jobs', {
    method: 'POST',
    json: { type: jobType, input }
  })
}

function get (jobId, options = {}) {
  return fetchJson(`/db/background-jobs/${jobId}`, options)
}

module.exports = {
  create,
  get
}