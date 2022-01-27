const fetchJson = require('./fetch-json')

export function scheduleClassEmail (options) {
  return fetchJson('/db/online-classes/schedule-class-email', {
    method: 'POST',
    json: options
  })
}
