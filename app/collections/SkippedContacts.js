// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let SkippedContacts;
import SkippedContact from 'models/SkippedContact';
import CocoCollection from 'collections/CocoCollection';

export default SkippedContacts = (function() {
  SkippedContacts = class SkippedContacts extends CocoCollection {
    static initClass() {
      this.prototype.model = SkippedContact;
      this.prototype.url = '/db/skipped-contact';
    }
  };
  SkippedContacts.initClass();
  return SkippedContacts;
})();
