const c = require('./../schemas')
const _ = require('lodash')

const AIScenarioSchema = c.object({
  title: 'AI Scenario',
  description: 'A generative AI scenario',
  required: ['releasePhase'],
  default: {
    releasePhase: 'beta',
    interactions: { start: [] }
  }
})

c.extendNamedProperties(AIScenarioSchema)

_.extend(AIScenarioSchema.properties, {
  description: {
    title: 'Description',
    description: 'A short explanation of what this scenario is about',
    type: 'string',
    maxLength: 2000,
    format: 'markdown'
  },
  mode: {
    type: 'string',
    title: 'Mode',
    description: 'Which mode this scenario is for (learn to use, practice using, etc.)',
    enum: ['learn to use', 'practice using', 'use', 'teach how to use']
  },
  tool: {
    type: 'string',
    title: 'Tool',
    description: 'Which generative AI tool this scenario is for (ChatGPT 4, ChatGPT 3.5, Stable Diffusion, DALL-E 2, etc.)'
  },
  task: {
    type: 'string',
    title: 'Task',
    description: 'Which task verb this scenario is for (make, edit, explain, etc.)'
  },
  doc: {
    type: 'string',
    title: 'Doc',
    description: 'Which document type this scenario is for (a webpage, an essay, an image, etc.))'
  },
  releasePhase: {
    type: 'string',
    enum: ['beta', 'released'],
    title: 'Release Phase',
    description: 'Scenarios start off in beta, then are released when they are completed'
  },
  initialActionQueue: {
    type: 'array',
    description: 'Actions to add to a project when it is created from this scenario'
  }
})

AIScenarioSchema.definitions = { inlineInteraction: c.InlineInteractionSchema }
c.extendBasicProperties(AIScenarioSchema, 'ai_scenario')
// c.extendSearchableProperties(AIScenarioSchema)
// c.extendVersionedProperties(AIScenarioSchema, 'ai_scenario')
// c.extendPermissionsProperties(AIScenarioSchema, 'ai_scenario')
// c.extendPatchableProperties(AIScenarioSchema)
// c.extendTranslationCoverageProperties(AIScenarioSchema)

module.exports = AIScenarioSchema