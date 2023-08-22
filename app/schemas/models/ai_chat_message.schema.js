const c = require('./../schemas')
const _ = require('lodash')

const AIChatMessageSchema = c.object({
  title: 'AI Interaction',
  description: 'A generative AI interaction',
  required: ['actor', 'parent', 'parentKind']
})

_.extend(AIChatMessageSchema.properties, {
  actor: { type: 'string', title: 'Actor', enum: ['model', 'user', 'teacher', 'celebrate'] },
  parent: c.objectId({ refPath: 'parentKind', title: 'Parent', description: 'The parent chat of this message', format: 'chat-message-parent-link'}),
  parentKind: { type: 'string', title: 'Kind', enum: ['scenario', 'project'], description: 'Whether this message is part of a scenario or project chat' },
  sentAt: { type: 'number' },
  text: {
    type: 'string',
    title: 'Chat Message Text',
    description: 'The content text of the chat message'
  },
  document: c.objectId({title:'Document', format:'ai-document-link'}),
  preview: {
    type: 'string',
    title: 'Preview',
    maxLength: 300,
    description: 'A preview of the document in the message discussed'
  },
  created: c.date({ title: 'Created' }),
  actionData: c.object({
    title: 'Data',
    description: 'Data associated with the message action',
    additionalProperties: true
  }, {
    choices: c.array({ title: 'Choices', description: 'Choices for the user to select from' }, c.object({
      title: 'Choice',
      description: 'A choice for the user to select from',
      additionalProperties: true
    }, {
      text: { type: 'string', title: 'Text', description: 'The text of the choice' },
      responseText: { type: 'string', title: 'Response', description: 'the response of the choice' },
      i18n: { type: 'object', format: 'i18n', props: ['text', 'responseText'], description: 'Help translate this property' }
    }))
  }),
  i18n: { type: 'object', format: 'i18n', props: ['text', 'preview'], description: 'Help translate this property' }
})

c.extendBasicProperties(AIChatMessageSchema, 'ai_chat_message')
c.extendSearchableProperties(AIChatMessageSchema)
c.extendTranslationCoverageProperties(AIChatMessageSchema)
// c.extendPermissionsProperties(AIInteractionSchema, 'ai_interaction')

module.exports = AIChatMessageSchema
