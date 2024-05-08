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

function confirmBooking (options) {
  const { eventId, code } = options
  return fetchJson(`/db/trial-classes/${eventId}/confirm/${code}`, {
    method: 'POST',
  })
}

function getTrialClasses (options) {
  return fetchJson('/db/trial-classes', {
    data: options
  })
}

module.exports = {
  scheduleClassEmail,
  fetchAvailableTime,
  tempBookTime,
  bookTime,
  confirmBooking,
  getTrialClasses
}
