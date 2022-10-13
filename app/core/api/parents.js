const fetchJson = require('./fetch-json')

module.exports = {
  sendFormEntry (options) {
    return fetchJson('/parents/schedule-free-class', {
      method: 'POST',
      json: options
    })
  },
  getAvailability () {
    return fetchJson('/parents/admin-availability', {
      method: 'GET',
    })
  },
  updateAvailabilityStatus (status = 'on') {
    return fetchJson('/parents/update-admin-availability-status', {
      method: 'PUT',
      json: { status }
    })
  }
}
