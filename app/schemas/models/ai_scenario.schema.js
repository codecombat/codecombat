// WARNING: This file is auto-generated from within AI HackStack. Do not edit directly.
// Instead, edit the corresponding Zod schema in the HackStack repo and run `npm run build` or `npm run build:schemas
//
// Last updated: 2024-10-03T19:41:05.121Z

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
    enum: ['learn to use', 'use', 'practice', 'capstone'],
  },
  tool: {
    title: 'Tool',
    type: 'string',
    description:
      'Which generative AI tool this scenario is for (ChatGPT 4, ChatGPT 3.5, Stable Diffusion, DALL-E 2, etc.)',
    minLength: 1,
  },
  task: {
    title: 'Task',
    type: 'string',
    description: 'Which task verb this scenario is for (make, edit, explain, etc.)',
    minLength: 1,
  },
  doc: {
    title: 'Doc',
    type: 'string',
    description: 'Which document type this scenario is for (a webpage, an essay, an image, etc.))',
    minLength: 1,
  },
  releasePhase: {
    title: 'Release Phase',
    type: 'string',
    description:
      'Scenarios are initially created as drafts, start off publicly in beta, then are released when they are completed',
    enum: ['beta', 'released', 'draft'],
  },
  labels: c.array({ title: 'Labels', description: 'Labels to help categorize this scenario', uniqueItems: true }, {
    type: 'string',
    enum: ['advertise', 'code', 'graph', 'draw', 'write', 'simulate', 'model', 'study', 'solve', 'learn'],
  }),
  initialActionQueue: {
    title: 'Initial Action Queue',
    type: 'array',
    description: 'Actions to add to a project when it is created from this scenario',
    items: { type: ['object', 'string'], format: 'chat-message-link' },
  },
  archived: { title: 'Archived', type: 'boolean' },
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
    inEditor: 'codecombat',
  },
  priority: { title: 'Priority', type: 'integer', description: 'Lower numbers will show earlier.' },
  promptType: {
    title: 'Prompt Type',
    type: 'string',
    description: 'The type of system prompt that will be used for this project',
    enum: ['math_1', 'math_2', 'english_1', 'english_2', 'code_1', 'code_2', 'ail_mentor', 'empty'],
    format: 'prompt-type',
  },
  additionalSystemPrompts: {
    title: 'Additional system prompts',
    type: 'array',
    maxItems: 3,
    items: {
      type: 'string',
      format: 'markdown',
    },
  },
  evaluationRules: {
    title: 'Evalualtion Rules',
    description: 'Evaluation Rules in System prompts for evaluating the project',
    type: 'array',
    items: {
      type: 'string',
      format: 'markdown',
    },
  },
  evaluationPhase: {
    title: 'Evaluation Phase',
    enum: ['internalRelease', 'released', 'draft'],
    description: "How far along the evaluationRules' development is, determining who sees it.",
  },
  minMsgs: {
    title: 'Minimum messages for completion',
    type: 'integer',
    description: 'The minimum number of messages required to mark a scenario as complete.',
  },
  allowFileUpload: {
    title: 'Allow File Upload',
    description: 'Allow user to upload file or not',
    type: 'boolean',
  },
  isStory: {
    title: 'Is Story',
    type: 'boolean',
    description: 'Play this scenario on the story (scene) page instead of the classic chat page',
  },
  forkOf: {
    title: 'Fork Of',
    type: 'string',
    description: 'Original id of the scenario this one was copied from, whatever the copy is for (joins analytics old ↔ new; provenance for content fixes)',
  },
  storyWorld: {
    title: 'Story World',
    type: 'string',
    description: 'Slug of the ai_story_world this level plays in (its planet). Its parent chain (normally galaxy) supplies HQ, HackStack and the shared scenes',
  },
  objectives: c.array({
    title: 'Objectives',
    description: 'Player-facing goals. A message activates one by id; the page shows the active one (chip) and can list all (goal panel). Criteria may be added per objective later',
  }, c.object({ title: 'Objective', required: ['id', 'text'] }, {
    id: { type: 'string', pattern: '^[a-z0-9-]+$' },
    text: { type: 'string' },
    i18n: { type: 'object', format: 'i18n', props: ['text'], description: 'Help translate this property' },
    completeOn: c.object({ title: 'Complete when' }, {
      kind: {
        type: 'string',
        enum: ['quiz-correct', 'prompt-replied'],
        title: 'Kind',
        description: "quiz-correct: a quiz answered correctly; prompt-replied: a HackStack reply to the player's own prompt. Absent: whichever comes first after the line that names it",
      },
    }),
    hidden: { type: 'boolean', title: 'Hidden', description: 'No pip until a line names it (a surprise goal)' },
  })),
  characters: c.array({
    title: 'Characters',
    description: 'One-off characters for this level only; resolved before the world chain. Usually empty',
  }, c.storyCharacter),
  backgrounds: c.array({
    title: 'Backgrounds',
    description: 'The scenes of this level (level art). The first is shown at start; messages switch by id; ids not found here resolve through the world chain',
  }, c.storyBackground),
})

AIScenarioSchema.required = ['mode', 'tool', 'task', 'doc', 'releasePhase', 'initialActionQueue']

c.extendNamedProperties(AIScenarioSchema, 'ai_scenario')
c.extendBasicProperties(AIScenarioSchema, 'ai_scenario')
c.extendSearchableProperties(AIScenarioSchema, 'ai_scenario')
c.extendVersionedProperties(AIScenarioSchema, 'ai_scenario')
c.extendPatchableProperties(AIScenarioSchema, 'ai_scenario')
c.extendTranslationCoverageProperties(AIScenarioSchema, 'ai_scenario')

module.exports = AIScenarioSchema
