// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let PatchesCollection
const PatchModel = require('models/Patch')
const CocoCollection = require('collections/CocoCollection')

module.exports = (PatchesCollection = (function () {
  PatchesCollection = class PatchesCollection extends CocoCollection {
    static initClass () {
      this.prototype.model = PatchModel
    }

    constructor (models, options, forModel, status) {
      super(...arguments)
      if (!status) { status = 'pending' }
      this.status = status
      const identifier = !forModel.get('original') ? '_id' : 'original'
      this.url = `${forModel.urlRoot}/${forModel.get(identifier)}/patches?status=${this.status}`
    }
  }
  PatchesCollection.initClass()
  return PatchesCollection
})())
