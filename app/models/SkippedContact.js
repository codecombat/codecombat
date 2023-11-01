/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let SkippedContact;
const CocoModel = require('./CocoModel');

module.exports = (SkippedContact = (function() {
  SkippedContact = class SkippedContact extends CocoModel {
    static initClass() {
      this.className = "SkippedContact";
      this.prototype.urlRoot = "/db/skipped-contact";
    }
  };
  SkippedContact.initClass();
  return SkippedContact;
})());
  // @schema: require 'schemas/models/skipped_contact.schema'
