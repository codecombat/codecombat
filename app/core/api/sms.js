const fetchJson = require('./fetch-json')

module.exports = {
  sendSMSRegister (options) {
    return fetchJson('/sms/register', _.assign({}, options, { method: 'POST' }))
  },
  sendSMSLogin (options) {
    return fetchJson('/sms/login', _.assign({}, options, { method: 'POST' }))
  },
}
