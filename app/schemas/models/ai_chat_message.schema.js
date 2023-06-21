const c = require('./../schemas')
const _ = require('lodash')

const AIChatMessageSchema = c.object({
  title: 'AI Interaction',
  description: 'A generative AI interaction',
})

_.extend(AIChatMessageSchema.properties, {
  actor: { type: 'string', enum: ['model', 'user', 'teacher'] },
  project: c.objectId(),
  sentAt: c.date({ title: 'Sent', description: 'The time the message started being sent' }),
  text: {
    type: 'string',
    title: 'Chat Message Text',
    description: 'The content text of the chat message'
  },
  document: c.objectId(),
  preview: {
    type: 'string',
    title: 'Preview',
    maxLength: 300,
    description: 'A preview of the document in the message discussed'
  }
})

// AIChatMessageSchema.definitions = {}
c.extendBasicProperties(AIChatMessageSchema, 'ai_chat_message')
// c.extendSearchableProperties(AIInteractionSchema)
// c.extendPermissionsProperties(AIInteractionSchema, 'ai_interaction')

module.exports = AIChatMessageSchema
