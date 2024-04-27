const fetchJson = require('./fetch-json')

function scheduleClassEmail (options) {
  return fetchJson('/contact/send-class-schedule-email', {
    method: 'POST',
    json: options
  })
}

function fetchAvailableTime (options) {
  return fetchJson('/db/trial-classes/available', {
    data: options
  })
}

function tempBookTime (options) {
  return fetchJson('/db/trial-classes/book/temp', {
    method: 'POST',
    json: options
  })
}

function bookTime (options) {
  return fetchJson('/db/trial-classes/book', {
    method: 'POST',
    json: options
  })
}

module.exports = {
  scheduleClassEmail,
  fetchAvailableTime,
  tempBookTime,
  bookTime
}
