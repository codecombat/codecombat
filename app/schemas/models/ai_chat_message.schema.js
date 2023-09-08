// WARNING: This file is auto-generated from within AI HackStack. Do not edit directly.
// Instead, edit the corresponding Zod schema in the HackStack repo and run `npm run build` or `npm run build:schemas
//
// Last updated: 2023-09-01T06:15:18.648Z

const _ = require('lodash')
const c = require('./../schemas')

const AIChatMessageSchema = c.object({
  title: 'AI Chat Message',
  description: 'A generative AI interaction',
})

_.extend(AIChatMessageSchema.properties, {
  actor: { title: 'Actor', type: 'string', enum: ['user', 'model', 'teacher', 'celebrate'] },
  parent: {
    title: 'Parent',
    type: ['object', 'string'],
    description: 'The parent chat of this message',
    format: 'chat-message-parent-link',
    refPath: 'parentKind',
  },
  parentKind: {
    title: 'Parent Kind',
    type: 'string',
<<<<<<< variant A
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
>>>>>>> variant B
    description: 'Whether this message is part of a scenario or project chat',
    enum: ['scenario', 'project'],
  },
  sentAt: { title: 'Sent At', type: 'number' },
  text: { title: 'Text', type: 'string', description: 'The content text of the chat message' },
  documents: {
    title: 'Documents',
    type: 'array',
    description: 'The attached AI Document objects',
    items: { type: 'string', links: [{ rel: 'db', href: '/db/level/{($)}/version' }], format: 'ai-document-link' },
  },
  actionData: {
    title: 'Action Data',
    type: 'object',
    description: 'Metadata for rendering this chat message as an action UI element',
  },
####### Ancestor
    title: 'Preview',
    maxLength: 300,
    description: 'A preview of the document in the message discussed'
  },
  created: c.date({ title: 'Created' }),
  actionData: {
    type: 'object',
    title: 'Data',
    description: 'Data associated with the message action'
  }
======= end
})

AIChatMessageSchema.required = ['actor', 'parent', 'parentKind', 'sentAt', 'text', 'documents']

c.extendBasicProperties(AIChatMessageSchema, 'ai_chat_message')
<<<<<<< variant A
c.extendSearchableProperties(AIChatMessageSchema)
c.extendTranslationCoverageProperties(AIChatMessageSchema)
// c.extendPermissionsProperties(AIInteractionSchema, 'ai_interaction')
>>>>>>> variant B
c.extendSearchableProperties(AIChatMessageSchema, 'ai_chat_message')
####### Ancestor
c.extendSearchableProperties(AIChatMessageSchema)
// c.extendPermissionsProperties(AIInteractionSchema, 'ai_interaction')
======= end

module.exports = AIChatMessageSchema
