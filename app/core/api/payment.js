const fetchJson = require('./fetch-json')

module.exports = {
  fetchByRecipient (recipientId, opts) {
    if (opts == null) { opts = {} }
    if (opts.data == null) { opts.data = {} }
    opts.data.recipient = recipientId
    return fetchJson('/db/payment', opts)
  }
}