// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const CocoModel = require('./CocoModel')
const schema = require('schemas/models/clan.schema')

class Clan extends CocoModel {}

Clan.className = 'Clan'
Clan.schema = schema
Clan.prototype.urlRoot = '/db/clan'

module.exports = Clan
