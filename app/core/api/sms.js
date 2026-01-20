const fetchJson = require('./fetch-json')

module.exports = {
  sendSMSRegister (options) {
    return fetchJson('/sms/register', _.assign({}, options, { method: 'POST' }))
  },
}
