// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ThangTypeCollection;
import CocoCollection from 'collections/CocoCollection';
import ThangType from 'models/ThangType';

export default ThangTypeCollection = (function() {
  ThangTypeCollection = class ThangTypeCollection extends CocoCollection {
    static initClass() {
      this.prototype.url = '/db/thang.type';
      this.prototype.model = ThangType;
    }

    fetchHeroes() {
      return this.fetch({
        url: '/db/thang.type?view=heroes'
      });
    }
  };
  ThangTypeCollection.initClass();
  return ThangTypeCollection;
})();
