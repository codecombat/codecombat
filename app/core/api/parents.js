const fetchJson = require('./fetch-json')

const sendFormEntry = (options) => {
  return fetchJson('/parents/schedule-free-class', {
    method: 'POST',
    json: options
  })
}

module.exports = {
  sendFormEntry
}
