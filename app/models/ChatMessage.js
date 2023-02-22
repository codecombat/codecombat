import CocoModel from 'app/models/CocoModel'
import schema from 'schemas/models/chat_message.schema'

class ChatMessage extends CocoModel {
  serializeMessage () {
    const serialized = _.pick(this.get('message'), 'text', 'sender', 'startDate', 'endDate')
    serialized.messageId = this.get('_id')
    return serialized
  }
}

ChatMessage.className = 'ChatMessage'
ChatMessage.schema = schema
ChatMessage.urlRoot = '/db/chat_message'
ChatMessage.prototype.urlRoot = '/db/chat_message'
ChatMessage.prototype.defaults = {
  product: 'codecombat',
  kind: 'level-chat',
  releasePhase: 'beta'
}

module.exports = ChatMessage
