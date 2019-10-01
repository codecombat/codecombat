CocoModel = require './CocoModel'

module.exports = class SkippedContact extends CocoModel
  @className: "SkippedContact"
  urlRoot: "/db/skipped-contact"
  # @schema: require 'schemas/models/skipped_contact.schema'
