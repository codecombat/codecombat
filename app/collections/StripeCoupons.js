// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let StripeCoupons;
import StripeCoupon from 'models/StripeCoupon';
import CocoCollection from 'collections/CocoCollection';

export default StripeCoupons = (function() {
  StripeCoupons = class StripeCoupons extends CocoCollection {
    static initClass() {
      this.prototype.model = StripeCoupon;
      this.prototype.url = '/stripe/coupons';
    }
  };
  StripeCoupons.initClass();
  return StripeCoupons;
})();
    
