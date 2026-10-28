const { translatedPaths, staleTranslations } = require('lib/stale-translations')

describe('lib/stale-translations', function () {
  const MESSAGE = translatedPaths(require('schemas/models/ai_chat_message.schema'))
  const SCENARIO = translatedPaths(require('schemas/models/ai_scenario.schema'))
  const clone = value => JSON.parse(JSON.stringify(value))

  it('walks the schemas to the fields the server checks', function () {
    expect(MESSAGE).toEqual([
      { path: [], props: ['text'] },
      { path: ['actionData', 'choices', 0], props: ['text', 'responseText'] },
      { path: ['actionData', 'exits', 0], props: ['label'] },
    ])
    expect(SCENARIO).toEqual([
      { path: [], props: ['name', 'description'] },
      { path: ['objectives', 0], props: ['text'] },
      { path: ['characters', 0], props: ['name'] },
    ])
  })

  it('lists a changed source with the languages whose stored translation it still carries', function () {
    const prev = {
      name: 'Remix',
      i18n: { he: { name: 'רמיקס' } },
      objectives: [
        { id: 'recolor', text: 'Change the star', i18n: { he: { text: 'שנו את הכוכב' }, fr: { text: "Change l'étoile" } } },
        { id: 'share', text: 'Share it', i18n: { he: { text: 'שתפו' } } },
      ],
    }
    const next = clone(prev)
    next.objectives[0].text = "Change the star to the locals' colour"
    next.objectives[0].i18n.fr.text = "Change l'étoile à la couleur des locaux"
    expect(staleTranslations(prev, next, SCENARIO)).toEqual([{ at: ['objectives', 0], prop: 'text', langs: ['he'] }])
  })

  it('lists nothing for spaces at the ends, a translation sent with the new text, a removed source or a new document', function () {
    const prev = { text: 'Hello', i18n: { he: { text: 'שלום' } }, actionData: { type: 'end-of-lesson', exits: [{ kind: 'map', label: 'Map', i18n: { he: { label: 'מפה' } } }] } }
    const spaced = clone(prev)
    spaced.text = ' Hello\n'
    expect(staleTranslations(prev, spaced, MESSAGE)).toEqual([])
    const retranslated = clone(prev)
    retranslated.text = 'Hi'
    retranslated.i18n.he.text = 'היי'
    expect(staleTranslations(prev, retranslated, MESSAGE)).toEqual([])
    const unlabelled = clone(prev)
    delete unlabelled.actionData.exits[0].label
    expect(staleTranslations(prev, unlabelled, MESSAGE)).toEqual([])
    expect(staleTranslations(undefined, prev, MESSAGE)).toEqual([])
  })
})
