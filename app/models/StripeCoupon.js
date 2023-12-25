// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let StripeCoupon
const CocoModel = require('./CocoModel')

module.exports = (StripeCoupon = (function () {
  StripeCoupon = class StripeCoupon extends CocoModel {
    static initClass () {
      this.className = 'StripeCoupon'
      this.schema = {}
      this.prototype.urlRoot = '/stripe/coupons'
      this.prototype.idAttribute = 'id'
    }

    formatString () {
      const bits = [this.id]
      if (this.get('percent_off')) {
        bits.push(`(${this.get('percent_off')}% off)`)
      } else if (this.get('amount_off')) {
        bits.push(`($${this.get('amount_off')} off)`)
      }
      if (this.get('duration')) {
        bits.push(`(duration: ${this.get('duration')})`)
      }
      if (this.redeem_by) {
        bits.push(`(redeem by: ${moment(this.get('redeem_by')).format('lll')}`)
      }
      return bits.join(' ')
    }
  }
  StripeCoupon.initClass()
  return StripeCoupon
})())
