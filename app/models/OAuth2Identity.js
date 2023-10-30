import CocoModel from 'app/models/CocoModel'
import schema from 'schemas/models/oauth2identity.schema'

class OAuth2Identity extends CocoModel { }

OAuth2Identity.className = 'OAuth2Identity'
OAuth2Identity.schema = schema
OAuth2Identity.urlRoot = '/db/oauth2identity'
OAuth2Identity.prototype.urlRoot = '/db/oauth2identity'

module.exports = OAuth2Identity
