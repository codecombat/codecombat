const _ = require('lodash')
const c = require('./../schemas')

const AIJuniorScenarioSchema = c.object({
  title: 'AI HackStack Junior Scenario',
  description: 'A generative AI scenario for AI HackStack Junior',
  required: ['name'],
})

_.extend(AIJuniorScenarioSchema.properties, {
  description: { type: 'string', title: 'Description', description: 'Short, user-facing description' },
  releasePhase: {
    title: 'Release Phase',
    type: 'string',
    description: 'Scenarios are initially created as drafts, start off publicly in beta, then are released when they are completed',
    enum: ['beta', 'released', 'draft'],
  },
  i18n: {
    title: 'I18n',
    type: 'object',
    description: 'Help translate this property',
    format: 'i18n',
    props: ['name', 'description'],
  },
  coverImage: {
    title: 'Cover Image',
    type: 'string',
    description: 'The cover image for this scenario',
    format: 'image-file',
  },
  priority: {
    title: 'Priority',
    description: 'Lower numbers will show earlier.',
    type: 'integer'
  },
  gradeLevels: c.object({ title: 'Grade Levels', description: 'Grade range this scenario is appropriate for' }, {
    start: { type: 'string', enum: ['Pre-K', 'K', '1', '2', '3', '4', '5'] },
    end: { type: 'string', enum: ['Pre-K', 'K', '1', '2', '3', '4', '5'] }
  }),
  subjects: c.array({ title: 'Subjects', description: 'Subjects this scenario is appropriate for' }, {
    type: 'string',
    enum: ['math', 'ela', 'science', 'social-studies', 'art', 'technology', 'sel', 'music', 'computer-science', 'misc']
  }),
  concepts: c.array({ title: 'Learning Concepts', uniqueItems: true }, c.concept),
  inputs: c.array({ title: 'Input Elements', description: 'The AI project worksheets are constructed from these input elements' }, c.object({
    required: ['type'],
  }, {
    id: c.shortString(),
    type: { type: 'string', enum: ['image-field', 'checkbox', 'radio'] },
    styles: c.object({}, c.shortString()),
    label: c.shortString({ format: 'markdown' }),
    text: { type: 'string', format: 'markdown' },
    left: { type: 'number', format: 'percent' },
    top: { type: 'number', format: 'percent' },
    width: { type: 'number', format: 'percent' },
    height: { type: 'number', format: 'percent' },
    choices: c.array({}, c.object({ required: ['id', 'text'], default: { id: '', text: '' } }, {
      id: c.shortString(),
      text: c.shortString(),
      i18n: { type: 'object', format: 'i18n', props: ['text'] }
    })),
    freeChoice: { type: 'boolean', description: 'Whether to allow fill-in-the-blank free choice' },
    exampleValue: {
      oneOf: [
        { title: 'Value', type: 'string', maxLength: 30 },
        { title: 'Choices', type: 'array', items: { type: 'string' } },
        { title: 'Image', type: 'string', format: 'image-file', minLength: 31 },
      ]
    },
    i18n: { type: 'object', format: 'i18n', props: ['label', 'text'] }
  })),
  prompts: c.array({ title: 'Prompts', description: 'AI prompts that process the input fields' }, c.object({
    required: ['id', 'model', 'text']
  }, {
    id: c.shortString(),
    model: c.shortString(),
    text: { type: 'string' },
    modelOptions: {},
    files: c.array({ title: 'Files', description: 'Files to include with this prompt' }, c.shortString()),
    exampleResponse: { type: 'string', format: 'markdown' },
    exampleImage: { type: 'string', format: 'image-file' },
    i18n: { type: 'object', format: 'i18n', props: ['text', 'exampleResponse', 'exampleImage'] },
  })),
  output: c.object({ title: 'Output', description: 'Template for completed AI projects', required: ['html'] }, {
    html: { type: 'string', format: 'code', aceMode: 'ace/mode/html' },
    css: { type: 'string', format: 'code', aceMode: 'ace/mode/css' },
    js: { type: 'string', format: 'code', aceMode: 'ace/mode/javascript' },
  }),
})

c.extendNamedProperties(AIJuniorScenarioSchema, 'ai_junior_scenario')
c.extendBasicProperties(AIJuniorScenarioSchema, 'ai_junior_scenario')
c.extendSearchableProperties(AIJuniorScenarioSchema, 'ai_junior_scenario')
c.extendVersionedProperties(AIJuniorScenarioSchema, 'ai_junior_scenario')
c.extendPatchableProperties(AIJuniorScenarioSchema, 'ai_junior_scenario')
c.extendTranslationCoverageProperties(AIJuniorScenarioSchema, 'ai_junior_scenario')

module.exports = AIJuniorScenarioSchema
