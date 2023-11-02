CocoModel = require './CocoModel'

module.exports = class StripeCoupon extends CocoModel
  @className: 'StripeCoupon'
  @schema: {}
  urlRoot: '/stripe/coupons'
  idAttribute: 'id'
  
  formatString: ->
    bits = [@id]
    if @get('percent_off')
      bits.push "(#{@get('percent_off')}% off)"
    else if @get('amount_off')
      bits.push "($#{@get('amount_off')} off)"
    if @get('duration')
      bits.push "(duration: #{@get('duration')})"
    if @redeem_by
      bits.push "(redeem by: #{moment(@get('redeem_by')).format('lll')}"
    return bits.join(' ')
