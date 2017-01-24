SkippedContact = require 'models/SkippedContact'
CocoCollection = require 'collections/CocoCollection'

module.exports = class SkippedContacts extends CocoCollection
  model: SkippedContact
  url: '/db/skipped-contact'
