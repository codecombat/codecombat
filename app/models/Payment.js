/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let Payment;
const CocoModel = require('./CocoModel');

module.exports = (Payment = (function() {
  Payment = class Payment extends CocoModel {
    static initClass() {
      this.className = "Payment";
      this.prototype.urlRoot = "/db/payment";
    }
  };
  Payment.initClass();
  return Payment;
})());