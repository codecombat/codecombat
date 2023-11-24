// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const CocoClass = require('./CocoClass')

const namesCache = {}

class SystemNameLoader extends CocoClass {
  getName (id) { return namesCache[id]?.name }

  setName (system) { namesCache[system.get('original')] = { name: system.get('name') } }
}

module.exports = new SystemNameLoader()
