const c = require('./../schemas')
const _ = require('lodash')

const AIScenarioSchema = c.object({
  title: 'AI Scenario',
  description: 'A generative AI scenario',
})

_.extend(AIScenarioSchema.properties, {
  name: {
    type: 'string',
    title: 'Name',
    description: 'Which bot/user sent this message'
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
    description: 'Which generative AI tool this scenario is for (ChatGPT, Stable Diffusion, DALL-E 2, etc.)'
  },
  task: {
    type: 'string',
    title: 'Task',
    description: 'Which task verb this scenario is for (make, edit, explain, etc.)'
  },
  doc: {
    type: 'string',
    title: 'Doc',
    description: 'Which document type this scenario is for (a webpage, an essay, an image, etc.)'
  },
  releasePhase: {
    type: 'string',
    enum: ['draft', 'beta', 'released'],
    title: 'Release Phase',
    description: 'Scenarios start off in beta, then are released when they are completed'
  },
  initialActionQueue: c.array({
    title: 'Initial Action Queue',
    description: 'Actions to add to a project when it is created from this scenario'
  }, c.objectId({format: 'chat-message-link'})),
  i18n: { type: 'object', format: 'i18n', props: ['mode', 'task', 'doc', 'name', 'description'], description: 'Help translate this property' }
})

c.extendNamedProperties(AIScenarioSchema)
c.extendBasicProperties(AIScenarioSchema, 'ai_scenario')
c.extendSearchableProperties(AIScenarioSchema)
c.extendVersionedProperties(AIScenarioSchema, 'ai_scenario')
c.extendPatchableProperties(AIScenarioSchema)
c.extendTranslationCoverageProperties(AIScenarioSchema)
// c.extendPermissionsProperties(AIScenarioSchema, 'ai_scenario')

module.exports = AIScenarioSchema
