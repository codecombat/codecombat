// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let CodeLogCollection;
import CocoCollection from 'collections/CocoCollection';
import CodeLog from 'models/CodeLog';

export default CodeLogCollection = (function() {
  CodeLogCollection = class CodeLogCollection extends CocoCollection {
    static initClass() {
      this.prototype.url = '/db/codelogs';
      this.prototype.model = CodeLog;
    }

    fetchByUserID(userID, options) {
      if (options == null) { options = {}; }
      options.url = '/db/codelogs?filter[userID]="' + userID + '"';
      return this.fetch(options);
    }

    fetchBySlug(slug, options) {
      if (options == null) { options = {}; }
      options.url = '/db/codelogs?filter[levelSlug]="' + slug + '"';
      return this.fetch(options);
    }

    fetchLatest(options) {
      if (options == null) { options = {}; }
      options.url = '/db/codelogs?conditions[sort]="-_id"';
      return this.fetch(options);
    }
  };
  CodeLogCollection.initClass();
  return CodeLogCollection;
})();
