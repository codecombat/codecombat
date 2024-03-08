const fetchJson = require('./fetch-json')

function create (jobType, input, other = undefined) {
  let url = '/db/background-jobs'
  if (other) {
    url = '/' + other + url
  }
  return fetchJson(url, {
    method: 'POST',
    json: { type: jobType, input }
  })
}

function get (jobId, options = {}, other = undefined) {
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