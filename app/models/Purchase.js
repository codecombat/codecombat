// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let Purchase;
import CocoModel from './CocoModel';

export default Purchase = (function() {
  Purchase = class Purchase extends CocoModel {
    static initClass() {
      this.className = "Purchase";
      this.prototype.urlRoot = "/db/purchase";
      this.schema = require('schemas/models/purchase.schema');
    }
  
    static makeFor(toPurchase) {
      let purchase;
      return purchase = new Purchase({
        recipient: me.id,
        purchaser: me.id,
        purchased: {
          original: toPurchase.get('original'),
          collection: _.string.underscored(toPurchase.constructor.className)
        }
      });
    }
  };
  Purchase.initClass();
  return Purchase;
})();