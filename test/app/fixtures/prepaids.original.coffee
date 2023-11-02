Prepaids = require 'collections/Prepaids'

module.exports = new Prepaids([
  {
    _id: 'unused-prepaid'
    creator: 'teacher1'
    exhausted: false
    maxRedeemers: 2
    redeemers: []
  }
])
