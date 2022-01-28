const fetchJson = require('./fetch-json')

export function scheduleClassEmail (options) {
  return fetchJson('/contact/send-class-schedule-email', {
    method: 'POST',
    json: options
  })
}
