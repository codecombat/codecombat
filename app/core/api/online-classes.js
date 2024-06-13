const fetchJson = require('./fetch-json')

function scheduleClassEmail (options) {
  return fetchJson('/contact/send-class-schedule-email', {
    method: 'POST',
    json: options
  })
}

function fetchAvailableTime (options) {
  return fetchJson('/db/events', {
    data: Object.assign({
      type: 'trial-classes',
      status: 'available'
    }, options)
  })
}

function tempBookTime (options) {
  return fetchJson('/db/trial-classes', {
    method: 'POST',
    json: Object.assign({
      action: 'book',
      actionType: 'temp'
    }, options)
  })
}

function bookTime (options) {
  return fetchJson('/db/trial-classes', {
    method: 'POST',
    json: Object.assign({
      action: 'book'
    }, options)
  })
}

function confirmBooking (options) {
  return fetchJson('/db/trial-classes', {
    method: 'POST',
    json: Object.assign({
      action: 'confirm'
    }, options)
  })
}

function getTrialClasses (options = {}) {
  return fetchJson('/db/trial-classes', {
    data: options
  })
}

function getGoogleCalendarSync (options) {
  return fetchJson('/db/trial-classes/google-calendar-sync', {
    method: 'PUT'
  })
}

module.exports = {
  scheduleClassEmail,
  fetchAvailableTime,
  tempBookTime,
  bookTime,
  confirmBooking,
  getTrialClasses,
  getGoogleCalendarSync
}
