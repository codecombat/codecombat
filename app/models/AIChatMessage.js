import CocoModel from 'app/models/CocoModel'
import schema from 'schemas/models/ai_chat_message.schema'

class AIChatMessage extends CocoModel { }

AIChatMessage.className = 'AIChatMessage'
AIChatMessage.schema = schema
AIChatMessage.urlRoot = '/db/ai_chat_message'
AIChatMessage.prototype.urlRoot = '/db/ai_chat_message'
AIChatMessage.prototype.defaults = {}

module.exports = AIChatMessage
