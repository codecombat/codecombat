// WARNING: This file is auto-generated from within AI HackStack. Do not edit directly.
// Instead, edit the corresponding Zod schema in the HackStack repo and run `npm run build` or `npm run build:schemas
//
// Last updated: 2023-09-08T05:55:38.100Z

const _ = require('lodash')
const c = require('./../schemas')

const AIScenarioSchema = c.object({
  title: 'AI Scenario',
  description: 'A generative AI scenario',
})

_.extend(AIScenarioSchema.properties, {
  persona: {
    title: 'Persona',
    type: 'string',
    description: 'Which persona this scenario is for (kid, teacher, parent, etc.)',
  },
  mode: {
    title: 'Mode',
    type: 'string',
    description: 'Which mode this scenario is for (learn to use, practice using, etc.)',
    enum: ['learn to use', 'practice using', 'use', 'teach how to use'],
  },
  tool: {
    title: 'Tool',
    type: 'string',
    description:
      'Which generative AI tool this scenario is for (ChatGPT 4, ChatGPT 3.5, Stable Diffusion, DALL-E 2, etc.)',
  },
  task: {
    title: 'Task',
    type: 'string',
    description: 'Which task verb this scenario is for (make, edit, explain, etc.)',
  },
  doc: {
    title: 'Doc',
    type: 'string',
    description: 'Which document type this scenario is for (a webpage, an essay, an image, etc.))',
  },
  releasePhase: {
    title: 'Release Phase',
    type: 'string',
    description:
      'Scenarios are initially created as drafts, start off publicly in beta, then are released when they are completed',
    enum: ['beta', 'released', 'draft'],
  },
  initialActionQueue: {
    title: 'Initial Action Queue',
    type: 'array',
    description: 'Actions to add to a project when it is created from this scenario',
    items: { type: ['object', 'string'], format: 'chat-message-link' },
  },
  i18n: {
    title: 'I18n',
    type: 'object',
    description: 'Help translate this property',
    format: 'i18n',
    props: ['mode', 'task', 'doc', 'name', 'description']
  }
})

AIScenarioSchema.required = ['mode', 'tool', 'task', 'doc', 'releasePhase', 'initialActionQueue']

c.extendNamedProperties(AIScenarioSchema, 'ai_scenario')
c.extendBasicProperties(AIScenarioSchema, 'ai_scenario')
c.extendSearchableProperties(AIScenarioSchema, 'ai_scenario')
c.extendVersionedProperties(AIScenarioSchema, 'ai_scenario')
c.extendPatchableProperties(AIScenarioSchema, 'ai_scenario')
c.extendTranslationCoverageProperties(AIScenarioSchema, 'ai_scenario')

module.exports = AIScenarioSchema
