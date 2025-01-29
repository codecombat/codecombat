const fetchJson = require('./fetch-json')
const { sleep } = require('lib/common-utils')

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
    // todo: move this logic into fetchJson
    url = '/' + other + url
  }
  return fetchJson(url, options)
}

async function pollTillResult (jobId, other, options = {}) {
  let url = `/db/background-jobs/${jobId}`
  if (other) {
    url = '/' + other + url
  }
  let job = await fetchJson(url, options)
  const MAX_ATTEMPTS = 30
  const DELAY_MS = 5000
  let attempts = 0
  while (job.status !== 'completed' && job.status !== 'failed' && attempts < MAX_ATTEMPTS) {
    await sleep(DELAY_MS)
    job = await fetchJson(url, options)
    attempts++
  }
  if (job.status === 'completed') {
    return JSON.parse(job.output)
  }
  if (job.status === 'failed') {
    throw new Error(job.message)
  }
  if (attempts === MAX_ATTEMPTS) {
    throw new Error('Failed to load the results')
  }
}

module.exports = {
  create,
  get,
  pollTillResult,
}
