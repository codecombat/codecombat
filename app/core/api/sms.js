const fetchJson = require('./fetch-json')

module.exports = {
  sendChinaSMSRegister (options) {
    return fetchJson('/sms/china/register', _.assign({}, options, { method: 'POST' }))
  },
}
