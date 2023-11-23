// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let Payments
const Payment = require('models/Payment')
const CocoCollection = require('collections/CocoCollection')

module.exports = (Payments = (function () {
  Payments = class Payments extends CocoCollection {
    static initClass () {
      this.prototype.model = Payment
      this.prototype.url = '/db/payment'
    }

    fetchByRecipient (recipientId, opts) {
      if (opts == null) { opts = {} }
      if (opts.data == null) { opts.data = {} }
      opts.data.recipient = recipientId
      return this.fetch(opts)
    }
  }
  Payments.initClass()
  return Payments
})())
