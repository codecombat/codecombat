StripeCoupon = require 'models/StripeCoupon'
CocoCollection = require 'collections/CocoCollection'

module.exports = class StripeCoupons extends CocoCollection
  model: StripeCoupon
  url: '/stripe/coupons'
    
