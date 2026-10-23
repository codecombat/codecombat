// Hand-maintained; the HackStack schema generator must not overwrite this file.
// Zod twin: hackstack/src/schemas/ai_story_world.ts

const c = require('./../schemas')

const AIStoryWorldSchema = c.object({
  title: 'AI Story World',
  description: 'Shared cast and scenes for HackStack story scenarios; worlds inherit from parentWorld (default: galaxy)',
})

c.extendNamedProperties(AIStoryWorldSchema)
AIStoryWorldSchema.properties.description = { type: 'string', title: 'Description', format: 'markdown' }
AIStoryWorldSchema.properties.parentWorld = {
  type: 'string',
  title: 'Parent World',
  description: 'Slug of the world this one inherits from. Absent = galaxy. The galaxy world has none.',
}
AIStoryWorldSchema.properties.characters = c.array({ title: 'Characters' }, c.storyCharacter)
AIStoryWorldSchema.properties.backgrounds = c.array({ title: 'Backgrounds' }, c.storyBackground)
AIStoryWorldSchema.properties.i18n = {
  type: 'object',
  format: 'i18n',
  props: ['name', 'description'],
  description: 'Help translate this property',
}

c.extendBasicProperties(AIStoryWorldSchema, 'ai_story_world')
c.extendSearchableProperties(AIStoryWorldSchema)
c.extendTranslationCoverageProperties(AIStoryWorldSchema)

module.exports = AIStoryWorldSchema
