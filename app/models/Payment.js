CocoModel = require('./CocoModel')

module.exports = class Payment extends CocoModel
  @className: "Payment"
  urlRoot: "/db/payment"