// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let StripeCoupons;
const StripeCoupon = require('models/StripeCoupon');
const CocoCollection = require('collections/CocoCollection');

module.exports = (StripeCoupons = (function() {
  StripeCoupons = class StripeCoupons extends CocoCollection {
    static initClass() {
      this.prototype.model = StripeCoupon;
      this.prototype.url = '/stripe/coupons';
    }
  };
  StripeCoupons.initClass();
  return StripeCoupons;
})());
    
