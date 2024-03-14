const fetchJson = require('./fetch-json')

function create (jobType, input, other) {
  let url = '/db/background-jobs'
  if (other) {
    url = '/' + other + url
  }
  return fetchJson(url, {
    method: 'POST',
    json: { type: jobType, input }
  })
}

function get (jobId, other, options = {}) {
  let url = `/db/background-jobs/${jobId}`
  if (other) {
    url = '/' + other + url
  }
  return fetchJson(url, options)
}

module.exports = {
  create,
  get
}