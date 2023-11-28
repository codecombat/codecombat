// WARNING: This file is auto-generated from within AI HackStack. Do not edit directly.
// Instead, edit the corresponding Zod schema in the HackStack repo and run `npm run build` or `npm run build:schemas
//
// Last updated: 2023-09-08T05:55:38.100Z

const _ = require('lodash')
const c = require('./../schemas')

const AIChatMessageSchema = c.object({
  title: 'AI Chat Message',
  description: 'A generative AI interaction'
})

_.extend(AIChatMessageSchema.properties, {
  actor: { title: 'Actor', type: 'string', enum: ['user', 'model', 'teacher', 'celebrate'] },
  parent: {
    title: 'Parent',
    type: ['object', 'string'],
    description: 'The parent chat of this message',
    format: 'chat-message-parent-link',
    refPath: 'parentKind'
  },
  parentKind: {
    title: 'Parent Kind',
    type: 'string',
    description: 'Whether this message is part of a scenario or project chat',
    enum: ['scenario', 'project']
  },
  sentAt: { title: 'Sent At', type: 'number' },
  text: { title: 'Text', type: 'string', description: 'The content text of the chat message' },
  documents: {
    title: 'Documents',
    type: 'array',
    description: 'The attached AI Document objects',
    items: { type: 'string', links: [{ rel: 'db', href: '/db/level/{($)}/version' }], format: 'ai-document-link' }
  },
  actionData: {
    title: 'Action Data',
    type: 'object',
    description: 'Metadata for rendering this chat message as an action UI element',
    additionalProperties: true,
    properties: {
      choices: {
        type: 'array',
        description: 'A choice for the user to select from',
        items: {
          type: 'object',
          additionalProperties: true,
          properties: {
            text: { type: 'string', title: 'Text', description: 'Text of the choice' },
            responseText: { type: 'string', title: 'Response', description: 'the response of the choice' },
            i18n: {
              type: 'object',
              format: 'i18n',
              props: ['text', 'responseText'],
              description: 'Help translate this property'
            }
          }
        }
      }
    }
  },
  i18n: { title: 'I18n', type: 'object', description: 'Help translate this property', format: 'i18n', props: ['text'] }
})

AIChatMessageSchema.required = ['actor', 'parent', 'parentKind', 'sentAt', 'text', 'documents']

c.extendBasicProperties(AIChatMessageSchema, 'ai_chat_message')
c.extendSearchableProperties(AIChatMessageSchema, 'ai_chat_message')
c.extendTranslationCoverageProperties(AIChatMessageSchema, 'ai_chat_message')

module.exports = AIChatMessageSchema
