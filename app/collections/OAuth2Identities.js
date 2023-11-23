// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let OAuth2IdentityCollection
const CocoCollection = require('collections/CocoCollection')
const OAuth2Identity = require('models/OAuth2Identity')

module.exports = (OAuth2IdentityCollection = (function () {
  OAuth2IdentityCollection = class OAuth2IdentityCollection extends CocoCollection {
    static initClass () {
      this.prototype.url = '/db/oauth2identity'
      this.prototype.model = OAuth2Identity
    }

    fetchForProvider (provider) {
      return this.fetch({ data: { filter: { provider } } })
        .then(() => this.models)
    }
  }
  OAuth2IdentityCollection.initClass()
  return OAuth2IdentityCollection
})())
